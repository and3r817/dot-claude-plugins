# Coroutine Integrations

Integration patterns for using Kotlin Coroutines with popular Android libraries.

## Retrofit Integration

### Basic Setup

```kotlin
// build.gradle.kts
implementation("com.squareup.retrofit2:retrofit:2.9.0")
implementation("com.squareup.retrofit2:converter-moshi:2.9.0")
```

### Suspend Functions in API Interface

```kotlin
interface UserApi {
    @GET("users/{id}")
    suspend fun getUser(@Path("id") id: String): User

    @GET("users")
    suspend fun getUsers(): List<User>

    @POST("users")
    suspend fun createUser(@Body user: User): User

    @DELETE("users/{id}")
    suspend fun deleteUser(@Path("id") id: String)
}
```

### Response Wrapper for Error Handling

```kotlin
interface UserApi {
    @GET("users/{id}")
    suspend fun getUser(@Path("id") id: String): Response<User>
}

class UserRepository @Inject constructor(
    private val api: UserApi,
    @IoDispatcher private val dispatcher: CoroutineDispatcher
) {
    suspend fun getUser(id: String): Result<User> = withContext(dispatcher) {
        runCatching {
            val response = api.getUser(id)
            if (response.isSuccessful) {
                response.body() ?: throw NoSuchElementException("User not found")
            } else {
                throw HttpException(response)
            }
        }
    }
}
```

### Custom Call Adapter for Result

```kotlin
class ResultCallAdapter<T>(
    private val successType: Type
) : CallAdapter<T, Call<Result<T>>> {

    override fun responseType(): Type = successType

    override fun adapt(call: Call<T>): Call<Result<T>> {
        return ResultCall(call)
    }
}

class ResultCall<T>(
    private val delegate: Call<T>
) : Call<Result<T>> {

    override fun enqueue(callback: Callback<Result<T>>) {
        delegate.enqueue(object : Callback<T> {
            override fun onResponse(call: Call<T>, response: Response<T>) {
                val result = if (response.isSuccessful) {
                    Result.success(response.body()!!)
                } else {
                    Result.failure(HttpException(response))
                }
                callback.onResponse(this@ResultCall, Response.success(result))
            }

            override fun onFailure(call: Call<T>, t: Throwable) {
                callback.onResponse(
                    this@ResultCall,
                    Response.success(Result.failure(t))
                )
            }
        })
    }

    // ... other Call methods
}
```

## Room Integration

### DAO with Flow

```kotlin
@Dao
interface UserDao {
    // One-shot query
    @Query("SELECT * FROM users WHERE id = :id")
    suspend fun getUser(id: String): UserEntity?

    // Observable query
    @Query("SELECT * FROM users WHERE id = :id")
    fun observeUser(id: String): Flow<UserEntity?>

    // Observable list
    @Query("SELECT * FROM users ORDER BY name")
    fun observeAllUsers(): Flow<List<UserEntity>>

    // Insert/Update/Delete
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(user: UserEntity)

    @Update
    suspend fun update(user: UserEntity)

    @Delete
    suspend fun delete(user: UserEntity)

    @Query("DELETE FROM users")
    suspend fun deleteAll()

    // Transaction
    @Transaction
    suspend fun replaceAll(users: List<UserEntity>) {
        deleteAll()
        users.forEach { insert(it) }
    }
}
```

### Repository Pattern with Room

```kotlin
class UserRepository @Inject constructor(
    private val userDao: UserDao,
    private val userApi: UserApi,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) {
    // Offline-first pattern
    fun getUser(id: String): Flow<User?> {
        return userDao.observeUser(id)
            .map { it?.toDomain() }
            .onStart {
                // Refresh from network
                refreshUser(id)
            }
            .flowOn(ioDispatcher)
    }

    private suspend fun refreshUser(id: String) {
        try {
            val user = userApi.getUser(id)
            userDao.insert(user.toEntity())
        } catch (e: Exception) {
            // Log error, but don't fail the flow
            Timber.e(e, "Failed to refresh user")
        }
    }

    // Sync pattern
    suspend fun sync(): Result<Unit> = withContext(ioDispatcher) {
        runCatching {
            val users = userApi.getUsers()
            userDao.replaceAll(users.map { it.toEntity() })
        }
    }
}
```

### Paging with Room and Network

```kotlin
@OptIn(ExperimentalPagingApi::class)
class UserRemoteMediator @Inject constructor(
    private val database: AppDatabase,
    private val api: UserApi
) : RemoteMediator<Int, UserEntity>() {

    override suspend fun load(
        loadType: LoadType,
        state: PagingState<Int, UserEntity>
    ): MediatorResult {
        return try {
            val page = when (loadType) {
                LoadType.REFRESH -> 1
                LoadType.PREPEND -> return MediatorResult.Success(endOfPaginationReached = true)
                LoadType.APPEND -> {
                    val lastItem = state.lastItemOrNull()
                        ?: return MediatorResult.Success(endOfPaginationReached = true)
                    // Calculate next page
                    (state.pages.size + 1)
                }
            }

            val users = api.getUsers(page = page, limit = state.config.pageSize)

            database.withTransaction {
                if (loadType == LoadType.REFRESH) {
                    database.userDao().deleteAll()
                }
                database.userDao().insertAll(users.map { it.toEntity() })
            }

            MediatorResult.Success(endOfPaginationReached = users.isEmpty())
        } catch (e: Exception) {
            MediatorResult.Error(e)
        }
    }
}
```

## WorkManager Integration

### CoroutineWorker

```kotlin
@HiltWorker
class SyncWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted params: WorkerParameters,
    private val repository: SyncRepository
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            setProgress(workDataOf("status" to "syncing"))

            repository.sync()
                .onSuccess {
                    setProgress(workDataOf("status" to "completed"))
                    return Result.success()
                }
                .onFailure { e ->
                    if (runAttemptCount < 3) {
                        return Result.retry()
                    }
                    return Result.failure(
                        workDataOf("error" to e.message)
                    )
                }

            Result.success()
        } catch (e: Exception) {
            if (e is CancellationException) throw e
            Result.failure()
        }
    }

    override suspend fun getForegroundInfo(): ForegroundInfo {
        return ForegroundInfo(
            NOTIFICATION_ID,
            createNotification()
        )
    }
}
```

### Scheduling and Observing

```kotlin
class WorkScheduler @Inject constructor(
    private val workManager: WorkManager
) {
    fun schedulePeriodcSync() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val request = PeriodicWorkRequestBuilder<SyncWorker>(
            repeatInterval = 1,
            repeatIntervalTimeUnit = TimeUnit.HOURS
        )
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.EXPONENTIAL,
                WorkRequest.MIN_BACKOFF_MILLIS,
                TimeUnit.MILLISECONDS
            )
            .build()

        workManager.enqueueUniquePeriodicWork(
            "periodic_sync",
            ExistingPeriodicWorkPolicy.KEEP,
            request
        )
    }

    fun observeSyncStatus(): Flow<SyncStatus> {
        return workManager.getWorkInfosForUniqueWorkFlow("periodic_sync")
            .map { workInfos ->
                workInfos.firstOrNull()?.let { info ->
                    when (info.state) {
                        WorkInfo.State.RUNNING -> {
                            val status = info.progress.getString("status")
                            SyncStatus.Running(status)
                        }
                        WorkInfo.State.SUCCEEDED -> SyncStatus.Completed
                        WorkInfo.State.FAILED -> {
                            val error = info.outputData.getString("error")
                            SyncStatus.Failed(error)
                        }
                        else -> SyncStatus.Idle
                    }
                } ?: SyncStatus.Idle
            }
    }
}
```

## Firebase Integration

### Firestore with Flow

```kotlin
fun DocumentReference.asFlow(): Flow<DocumentSnapshot> = callbackFlow {
    val listener = addSnapshotListener { snapshot, error ->
        if (error != null) {
            close(error)
            return@addSnapshotListener
        }
        if (snapshot != null) {
            trySend(snapshot)
        }
    }
    awaitClose { listener.remove() }
}

fun Query.asFlow(): Flow<QuerySnapshot> = callbackFlow {
    val listener = addSnapshotListener { snapshot, error ->
        if (error != null) {
            close(error)
            return@addSnapshotListener
        }
        if (snapshot != null) {
            trySend(snapshot)
        }
    }
    awaitClose { listener.remove() }
}

// Usage
class FirestoreRepository @Inject constructor(
    private val firestore: FirebaseFirestore
) {
    fun observeUser(userId: String): Flow<User?> {
        return firestore.collection("users")
            .document(userId)
            .asFlow()
            .map { it.toObject<User>() }
    }

    fun observeUserPosts(userId: String): Flow<List<Post>> {
        return firestore.collection("posts")
            .whereEqualTo("authorId", userId)
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .asFlow()
            .map { snapshot ->
                snapshot.documents.mapNotNull { it.toObject<Post>() }
            }
    }
}
```

### Firebase Auth with Coroutines

```kotlin
suspend fun FirebaseAuth.awaitSignIn(
    email: String,
    password: String
): AuthResult = suspendCancellableCoroutine { cont ->
    signInWithEmailAndPassword(email, password)
        .addOnSuccessListener { result ->
            cont.resume(result)
        }
        .addOnFailureListener { e ->
            cont.resumeWithException(e)
        }
}

// Auth state as Flow
fun FirebaseAuth.authStateFlow(): Flow<FirebaseUser?> = callbackFlow {
    val listener = AuthStateListener { auth ->
        trySend(auth.currentUser)
    }
    addAuthStateListener(listener)
    awaitClose { removeAuthStateListener(listener) }
}
```

## DataStore Integration

### Preferences DataStore

```kotlin
class PreferencesRepository @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val Context.dataStore by preferencesDataStore(name = "settings")

    val darkMode: Flow<Boolean> = context.dataStore.data
        .catch { e ->
            if (e is IOException) emit(emptyPreferences())
            else throw e
        }
        .map { prefs ->
            prefs[PreferencesKeys.DARK_MODE] ?: false
        }

    suspend fun setDarkMode(enabled: Boolean) {
        context.dataStore.edit { prefs ->
            prefs[PreferencesKeys.DARK_MODE] = enabled
        }
    }

    // Atomic update
    suspend fun toggleDarkMode() {
        context.dataStore.edit { prefs ->
            val current = prefs[PreferencesKeys.DARK_MODE] ?: false
            prefs[PreferencesKeys.DARK_MODE] = !current
        }
    }
}

private object PreferencesKeys {
    val DARK_MODE = booleanPreferencesKey("dark_mode")
}
```

## Ktor Client Integration

```kotlin
// build.gradle.kts
implementation("io.ktor:ktor-client-core:2.3.7")
implementation("io.ktor:ktor-client-android:2.3.7")
implementation("io.ktor:ktor-client-content-negotiation:2.3.7")
implementation("io.ktor:ktor-serialization-kotlinx-json:2.3.7")

// Setup
val client = HttpClient(Android) {
    install(ContentNegotiation) {
        json(Json {
            ignoreUnknownKeys = true
            isLenient = true
        })
    }
    install(HttpTimeout) {
        requestTimeoutMillis = 15000
        connectTimeoutMillis = 10000
    }
}

// Repository
class KtorRepository @Inject constructor(
    private val client: HttpClient,
    @IoDispatcher private val dispatcher: CoroutineDispatcher
) {
    suspend fun getUser(id: String): Result<User> = withContext(dispatcher) {
        runCatching {
            client.get("https://api.example.com/users/$id").body()
        }
    }

    // Streaming response as Flow
    fun streamEvents(): Flow<ServerEvent> = flow {
        client.prepareGet("https://api.example.com/events").execute { response ->
            val channel: ByteReadChannel = response.body()
            while (!channel.isClosedForRead) {
                val line = channel.readUTF8Line() ?: break
                emit(parseEvent(line))
            }
        }
    }.flowOn(dispatcher)
}
```

## OkHttp Interceptor for Coroutines

```kotlin
class AuthInterceptor @Inject constructor(
    private val tokenProvider: TokenProvider
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        // Note: Interceptors run on OkHttp's thread pool
        // For suspend token refresh, use Authenticator instead
        val token = runBlocking {
            tokenProvider.getToken()
        }

        val request = chain.request().newBuilder()
            .addHeader("Authorization", "Bearer $token")
            .build()

        return chain.proceed(request)
    }
}

// Better: Use Authenticator for token refresh
class TokenAuthenticator @Inject constructor(
    private val tokenRepository: TokenRepository
) : Authenticator {

    override fun authenticate(route: Route?, response: Response): Request? {
        if (response.code != 401) return null

        val newToken = runBlocking {
            tokenRepository.refreshToken()
        } ?: return null

        return response.request.newBuilder()
            .header("Authorization", "Bearer $newToken")
            .build()
    }
}
```

## Location Services

```kotlin
class LocationRepository @Inject constructor(
    private val fusedLocationClient: FusedLocationProviderClient,
    @IoDispatcher private val dispatcher: CoroutineDispatcher
) {
    @SuppressLint("MissingPermission")
    suspend fun getCurrentLocation(): Location? = withContext(dispatcher) {
        suspendCancellableCoroutine { cont ->
            fusedLocationClient.getCurrentLocation(
                Priority.PRIORITY_HIGH_ACCURACY,
                CancellationTokenSource().token
            ).addOnSuccessListener { location ->
                cont.resume(location)
            }.addOnFailureListener { e ->
                cont.resumeWithException(e)
            }
        }
    }

    @SuppressLint("MissingPermission")
    fun locationUpdates(
        interval: Long = 10000,
        fastestInterval: Long = 5000
    ): Flow<Location> = callbackFlow {
        val request = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            interval
        ).apply {
            setMinUpdateIntervalMillis(fastestInterval)
        }.build()

        val callback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { trySend(it) }
            }
        }

        fusedLocationClient.requestLocationUpdates(
            request,
            callback,
            Looper.getMainLooper()
        )

        awaitClose {
            fusedLocationClient.removeLocationUpdates(callback)
        }
    }.flowOn(dispatcher)
}
```
