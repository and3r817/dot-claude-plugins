# Jetpack Integration Guide

Deep reference for integrating Jetpack libraries with Compose: Navigation, Room, Hilt, WorkManager, and DataStore.

## Navigation Compose

### Multi-Module Navigation

```kotlin
// :feature:home - HomeNavigation.kt
@Serializable
data object HomeGraph

@Serializable
data object HomeRoute

fun NavGraphBuilder.homeGraph(
    onNavigateToDetail: (String) -> Unit
) {
    navigation<HomeGraph>(startDestination = HomeRoute) {
        composable<HomeRoute> {
            HomeScreen(onNavigateToDetail = onNavigateToDetail)
        }
    }
}

// :feature:detail - DetailNavigation.kt
@Serializable
data object DetailGraph

@Serializable
data class DetailRoute(val id: String)

fun NavGraphBuilder.detailGraph(
    onNavigateBack: () -> Unit
) {
    navigation<DetailGraph>(startDestination = DetailRoute::class) {
        composable<DetailRoute> { backStackEntry ->
            val route: DetailRoute = backStackEntry.toRoute()
            DetailScreen(
                itemId = route.id,
                onNavigateBack = onNavigateBack
            )
        }
    }
}

// :app - AppNavHost.kt
@Composable
fun AppNavHost(
    navController: NavHostController = rememberNavController()
) {
    NavHost(
        navController = navController,
        startDestination = HomeGraph
    ) {
        homeGraph(
            onNavigateToDetail = { id ->
                navController.navigate(DetailRoute(id))
            }
        )
        detailGraph(
            onNavigateBack = { navController.popBackStack() }
        )
    }
}
```

### Deep Links

```kotlin
@Serializable
data class ProductRoute(val productId: String)

// In NavGraph
composable<ProductRoute>(
    deepLinks = listOf(
        navDeepLink {
            uriPattern = "https://example.com/product/{productId}"
            action = Intent.ACTION_VIEW
        },
        navDeepLink {
            uriPattern = "app://example/product/{productId}"
        }
    )
) { backStackEntry ->
    val route: ProductRoute = backStackEntry.toRoute()
    ProductScreen(productId = route.productId)
}

// AndroidManifest.xml
<activity android:name=".MainActivity">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="https"
            android:host="example.com"
            android:pathPrefix="/product" />
    </intent-filter>
</activity>
```

### Bottom Navigation

```kotlin
@Serializable sealed interface TopLevelRoute {
    @Serializable data object Home : TopLevelRoute
    @Serializable data object Search : TopLevelRoute
    @Serializable data object Profile : TopLevelRoute
}

data class TopLevelDestination(
    val route: TopLevelRoute,
    val icon: ImageVector,
    val label: String
)

val topLevelDestinations = listOf(
    TopLevelDestination(TopLevelRoute.Home, Icons.Default.Home, "Home"),
    TopLevelDestination(TopLevelRoute.Search, Icons.Default.Search, "Search"),
    TopLevelDestination(TopLevelRoute.Profile, Icons.Default.Person, "Profile")
)

@Composable
fun MainScreen() {
    val navController = rememberNavController()
    val currentBackStackEntry by navController.currentBackStackEntryAsState()

    Scaffold(
        bottomBar = {
            NavigationBar {
                topLevelDestinations.forEach { destination ->
                    val selected = currentBackStackEntry?.destination?.hasRoute(
                        destination.route::class
                    ) == true

                    NavigationBarItem(
                        selected = selected,
                        onClick = {
                            navController.navigate(destination.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { Icon(destination.icon, contentDescription = null) },
                        label = { Text(destination.label) }
                    )
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = TopLevelRoute.Home,
            modifier = Modifier.padding(padding)
        ) {
            composable<TopLevelRoute.Home> { HomeScreen() }
            composable<TopLevelRoute.Search> { SearchScreen() }
            composable<TopLevelRoute.Profile> { ProfileScreen() }
        }
    }
}
```

### Shared Element Transitions

```kotlin
@Composable
fun SharedElementExample() {
    val navController = rememberNavController()

    SharedTransitionLayout {
        NavHost(navController = navController, startDestination = "list") {
            composable("list") {
                AnimatedVisibilityScope {
                    ListScreen(
                        onItemClick = { item ->
                            navController.navigate("detail/${item.id}")
                        },
                        sharedTransitionScope = this@SharedTransitionLayout,
                        animatedVisibilityScope = this
                    )
                }
            }
            composable("detail/{id}") { backStackEntry ->
                AnimatedVisibilityScope {
                    DetailScreen(
                        itemId = backStackEntry.arguments?.getString("id") ?: "",
                        sharedTransitionScope = this@SharedTransitionLayout,
                        animatedVisibilityScope = this
                    )
                }
            }
        }
    }
}

@Composable
fun ListItem(
    item: Item,
    onClick: () -> Unit,
    sharedTransitionScope: SharedTransitionScope,
    animatedVisibilityScope: AnimatedVisibilityScope
) {
    with(sharedTransitionScope) {
        Card(onClick = onClick) {
            AsyncImage(
                model = item.imageUrl,
                contentDescription = null,
                modifier = Modifier
                    .sharedElement(
                        state = rememberSharedContentState(key = "image-${item.id}"),
                        animatedVisibilityScope = animatedVisibilityScope
                    )
            )
            Text(
                text = item.title,
                modifier = Modifier
                    .sharedBounds(
                        sharedContentState = rememberSharedContentState(key = "title-${item.id}"),
                        animatedVisibilityScope = animatedVisibilityScope
                    )
            )
        }
    }
}
```

## Room Database

### Database Migrations

```kotlin
@Database(
    entities = [UserEntity::class, PostEntity::class],
    version = 3,
    autoMigrations = [
        AutoMigration(from = 1, to = 2),
        AutoMigration(from = 2, to = 3, spec = Migration2To3::class)
    ],
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
    abstract fun postDao(): PostDao
}

// Manual migration for complex changes
val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE users ADD COLUMN avatar_url TEXT")
    }
}

// Auto migration spec for renames/deletes
@RenameColumn(tableName = "users", fromColumnName = "name", toColumnName = "full_name")
@DeleteColumn(tableName = "users", columnName = "deprecated_field")
class Migration2To3 : AutoMigrationSpec

// Provide database with migrations
@Provides
@Singleton
fun provideDatabase(@ApplicationContext context: Context): AppDatabase {
    return Room.databaseBuilder(
        context,
        AppDatabase::class.java,
        "app_database"
    )
    .addMigrations(MIGRATION_1_2)
    .fallbackToDestructiveMigration()  // Only for debug builds!
    .build()
}
```

### Relations and Embedded Objects

```kotlin
// One-to-many relationship
@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val userId: String,
    val name: String
)

@Entity(
    tableName = "posts",
    foreignKeys = [
        ForeignKey(
            entity = UserEntity::class,
            parentColumns = ["userId"],
            childColumns = ["authorId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("authorId")]
)
data class PostEntity(
    @PrimaryKey val postId: String,
    val authorId: String,
    val title: String,
    val content: String
)

data class UserWithPosts(
    @Embedded val user: UserEntity,
    @Relation(
        parentColumn = "userId",
        entityColumn = "authorId"
    )
    val posts: List<PostEntity>
)

// Many-to-many relationship
@Entity(tableName = "tags")
data class TagEntity(
    @PrimaryKey val tagId: String,
    val name: String
)

@Entity(
    tableName = "post_tag_cross_ref",
    primaryKeys = ["postId", "tagId"]
)
data class PostTagCrossRef(
    val postId: String,
    val tagId: String
)

data class PostWithTags(
    @Embedded val post: PostEntity,
    @Relation(
        parentColumn = "postId",
        entityColumn = "tagId",
        associateBy = Junction(PostTagCrossRef::class)
    )
    val tags: List<TagEntity>
)

@Dao
interface UserDao {
    @Transaction
    @Query("SELECT * FROM users WHERE userId = :id")
    fun getUserWithPosts(id: String): Flow<UserWithPosts?>
}

@Dao
interface PostDao {
    @Transaction
    @Query("SELECT * FROM posts WHERE postId = :id")
    fun getPostWithTags(id: String): Flow<PostWithTags?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPostWithTags(
        post: PostEntity,
        tags: List<TagEntity>,
        crossRefs: List<PostTagCrossRef>
    )
}
```

### Type Converters

```kotlin
class Converters {
    @TypeConverter
    fun fromTimestamp(value: Long?): Instant? {
        return value?.let { Instant.fromEpochMilliseconds(it) }
    }

    @TypeConverter
    fun instantToTimestamp(instant: Instant?): Long? {
        return instant?.toEpochMilliseconds()
    }

    @TypeConverter
    fun fromStringList(value: String?): List<String>? {
        return value?.split(",")?.map { it.trim() }
    }

    @TypeConverter
    fun stringListToString(list: List<String>?): String? {
        return list?.joinToString(",")
    }

    @TypeConverter
    fun fromJson(value: String?): CustomObject? {
        return value?.let { Json.decodeFromString(it) }
    }

    @TypeConverter
    fun customObjectToJson(obj: CustomObject?): String? {
        return obj?.let { Json.encodeToString(it) }
    }
}
```

### Paging with Room

```kotlin
@Dao
interface PostDao {
    @Query("SELECT * FROM posts ORDER BY created_at DESC")
    fun getPostsPagingSource(): PagingSource<Int, PostEntity>
}

class PostRepository @Inject constructor(
    private val postDao: PostDao
) {
    fun getPostsPager(): Flow<PagingData<Post>> {
        return Pager(
            config = PagingConfig(
                pageSize = 20,
                enablePlaceholders = false,
                prefetchDistance = 5
            ),
            pagingSourceFactory = { postDao.getPostsPagingSource() }
        ).flow.map { pagingData ->
            pagingData.map { it.toDomain() }
        }
    }
}

@HiltViewModel
class PostListViewModel @Inject constructor(
    repository: PostRepository
) : ViewModel() {
    val posts = repository.getPostsPager()
        .cachedIn(viewModelScope)
}

@Composable
fun PostList(viewModel: PostListViewModel = hiltViewModel()) {
    val posts = viewModel.posts.collectAsLazyPagingItems()

    LazyColumn {
        items(
            count = posts.itemCount,
            key = posts.itemKey { it.id }
        ) { index ->
            val post = posts[index]
            if (post != null) {
                PostItem(post = post)
            } else {
                PostItemPlaceholder()
            }
        }

        when (posts.loadState.append) {
            is LoadState.Loading -> {
                item { LoadingIndicator() }
            }
            is LoadState.Error -> {
                item {
                    ErrorRetry(
                        onRetry = { posts.retry() }
                    )
                }
            }
            else -> {}
        }
    }
}
```

## Hilt Advanced

### Scoped Dependencies

```kotlin
// Activity scoped
@Module
@InstallIn(ActivityComponent::class)
object ActivityModule {
    @Provides
    @ActivityScoped
    fun provideActivityAnalytics(activity: Activity): ActivityAnalytics {
        return ActivityAnalytics(activity)
    }
}

// ViewModel scoped (lives with ViewModel)
@Module
@InstallIn(ViewModelComponent::class)
object ViewModelModule {
    @Provides
    @ViewModelScoped
    fun provideSavedStateHandler(
        savedStateHandle: SavedStateHandle
    ): SavedStateHandler {
        return SavedStateHandler(savedStateHandle)
    }
}

// Fragment scoped
@Module
@InstallIn(FragmentComponent::class)
object FragmentModule {
    @Provides
    @FragmentScoped
    fun provideFragmentNavigator(fragment: Fragment): FragmentNavigator {
        return FragmentNavigator(fragment)
    }
}
```

### Qualifiers

```kotlin
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class IoDispatcher

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class MainDispatcher

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class DefaultDispatcher

@Module
@InstallIn(SingletonComponent::class)
object DispatcherModule {
    @Provides
    @IoDispatcher
    fun provideIoDispatcher(): CoroutineDispatcher = Dispatchers.IO

    @Provides
    @MainDispatcher
    fun provideMainDispatcher(): CoroutineDispatcher = Dispatchers.Main

    @Provides
    @DefaultDispatcher
    fun provideDefaultDispatcher(): CoroutineDispatcher = Dispatchers.Default
}

// Usage
class UserRepository @Inject constructor(
    private val userDao: UserDao,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) {
    suspend fun getUser(id: String) = withContext(ioDispatcher) {
        userDao.getUser(id)
    }
}
```

### Assisted Injection

```kotlin
class DetailViewModel @AssistedInject constructor(
    private val repository: Repository,
    @Assisted private val itemId: String
) : ViewModel() {

    @AssistedFactory
    interface Factory {
        fun create(itemId: String): DetailViewModel
    }
}

// Compose integration
@Composable
fun DetailScreen(
    itemId: String,
    viewModel: DetailViewModel = hiltViewModel(
        creationCallback = { factory: DetailViewModel.Factory ->
            factory.create(itemId)
        }
    )
) {
    // Screen content
}
```

### Entry Points

```kotlin
// For non-Hilt classes
@EntryPoint
@InstallIn(SingletonComponent::class)
interface AnalyticsEntryPoint {
    fun analytics(): Analytics
}

// Usage in non-Hilt class
class CustomView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : View(context, attrs) {

    private val analytics: Analytics

    init {
        val entryPoint = EntryPointAccessors.fromApplication(
            context.applicationContext,
            AnalyticsEntryPoint::class.java
        )
        analytics = entryPoint.analytics()
    }
}
```

## WorkManager

### Basic Worker with Hilt

```kotlin
@HiltWorker
class SyncWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted workerParams: WorkerParameters,
    private val repository: SyncRepository
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            repository.sync()
            Result.success()
        } catch (e: Exception) {
            if (runAttemptCount < 3) {
                Result.retry()
            } else {
                Result.failure()
            }
        }
    }
}

// Scheduling
@Singleton
class WorkScheduler @Inject constructor(
    private val workManager: WorkManager
) {
    fun scheduleSync() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .setRequiresBatteryNotLow(true)
            .build()

        val syncRequest = PeriodicWorkRequestBuilder<SyncWorker>(
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
            "sync_work",
            ExistingPeriodicWorkPolicy.KEEP,
            syncRequest
        )
    }
}
```

### Work Progress and Observation

```kotlin
@HiltWorker
class UploadWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted workerParams: WorkerParameters,
    private val uploadService: UploadService
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        val fileUri = inputData.getString("file_uri") ?: return Result.failure()

        setProgress(workDataOf("progress" to 0))

        return try {
            uploadService.upload(fileUri) { progress ->
                setProgress(workDataOf("progress" to progress))
            }
            Result.success(workDataOf("upload_url" to "https://..."))
        } catch (e: Exception) {
            Result.failure(workDataOf("error" to e.message))
        }
    }
}

// Observing in ViewModel
@HiltViewModel
class UploadViewModel @Inject constructor(
    private val workManager: WorkManager
) : ViewModel() {

    private val _uploadState = MutableStateFlow<UploadState>(UploadState.Idle)
    val uploadState: StateFlow<UploadState> = _uploadState.asStateFlow()

    fun startUpload(fileUri: Uri) {
        val request = OneTimeWorkRequestBuilder<UploadWorker>()
            .setInputData(workDataOf("file_uri" to fileUri.toString()))
            .build()

        workManager.enqueue(request)

        workManager.getWorkInfoByIdFlow(request.id)
            .onEach { workInfo ->
                when (workInfo?.state) {
                    WorkInfo.State.RUNNING -> {
                        val progress = workInfo.progress.getInt("progress", 0)
                        _uploadState.value = UploadState.Uploading(progress)
                    }
                    WorkInfo.State.SUCCEEDED -> {
                        val url = workInfo.outputData.getString("upload_url")
                        _uploadState.value = UploadState.Success(url!!)
                    }
                    WorkInfo.State.FAILED -> {
                        val error = workInfo.outputData.getString("error")
                        _uploadState.value = UploadState.Error(error ?: "Unknown error")
                    }
                    else -> {}
                }
            }
            .launchIn(viewModelScope)
    }
}
```

## DataStore

### Preferences DataStore

```kotlin
// Keys
object PreferencesKeys {
    val DARK_MODE = booleanPreferencesKey("dark_mode")
    val NOTIFICATION_ENABLED = booleanPreferencesKey("notifications")
    val USER_NAME = stringPreferencesKey("user_name")
}

// Repository
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

    val userPreferences: Flow<UserPreferences> = context.dataStore.data
        .map { prefs ->
            UserPreferences(
                darkMode = prefs[PreferencesKeys.DARK_MODE] ?: false,
                notificationsEnabled = prefs[PreferencesKeys.NOTIFICATION_ENABLED] ?: true,
                userName = prefs[PreferencesKeys.USER_NAME]
            )
        }
}
```

### Proto DataStore

```protobuf
// user_prefs.proto
syntax = "proto3";

option java_package = "com.example.app";
option java_multiple_files = true;

message UserPrefs {
  bool dark_mode = 1;
  bool notifications_enabled = 2;
  string user_name = 3;
  repeated string favorite_ids = 4;
}
```

```kotlin
// Serializer
object UserPrefsSerializer : Serializer<UserPrefs> {
    override val defaultValue: UserPrefs = UserPrefs.getDefaultInstance()

    override suspend fun readFrom(input: InputStream): UserPrefs {
        try {
            return UserPrefs.parseFrom(input)
        } catch (e: InvalidProtocolBufferException) {
            throw CorruptionException("Cannot read proto.", e)
        }
    }

    override suspend fun writeTo(t: UserPrefs, output: OutputStream) {
        t.writeTo(output)
    }
}

// Repository
class UserPrefsRepository @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val Context.userPrefsStore by dataStore(
        fileName = "user_prefs.pb",
        serializer = UserPrefsSerializer
    )

    val userPrefs: Flow<UserPrefs> = context.userPrefsStore.data

    suspend fun updateDarkMode(enabled: Boolean) {
        context.userPrefsStore.updateData { prefs ->
            prefs.toBuilder().setDarkMode(enabled).build()
        }
    }

    suspend fun addFavorite(id: String) {
        context.userPrefsStore.updateData { prefs ->
            prefs.toBuilder().addFavoriteIds(id).build()
        }
    }
}
```

## Lifecycle Integration

### ViewModel Events (Single-Shot)

```kotlin
@HiltViewModel
class FormViewModel @Inject constructor(
    private val repository: FormRepository
) : ViewModel() {

    private val _events = Channel<FormEvent>(Channel.BUFFERED)
    val events = _events.receiveAsFlow()

    fun submit(data: FormData) {
        viewModelScope.launch {
            repository.submit(data)
                .onSuccess {
                    _events.send(FormEvent.SubmitSuccess)
                }
                .onFailure { e ->
                    _events.send(FormEvent.SubmitError(e.message ?: "Unknown error"))
                }
        }
    }
}

sealed interface FormEvent {
    data object SubmitSuccess : FormEvent
    data class SubmitError(val message: String) : FormEvent
}

@Composable
fun FormScreen(
    viewModel: FormViewModel = hiltViewModel(),
    onNavigateToSuccess: () -> Unit
) {
    val snackbarHostState = remember { SnackbarHostState() }

    // Collect events with lifecycle awareness
    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is FormEvent.SubmitSuccess -> onNavigateToSuccess()
                is FormEvent.SubmitError -> {
                    snackbarHostState.showSnackbar(event.message)
                }
            }
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { padding ->
        FormContent(
            modifier = Modifier.padding(padding),
            onSubmit = viewModel::submit
        )
    }
}
```

### Process Death Handling

```kotlin
@HiltViewModel
class SearchViewModel @Inject constructor(
    private val savedStateHandle: SavedStateHandle,
    private val repository: SearchRepository
) : ViewModel() {

    // Survives process death
    var query by savedStateHandle.saveable { mutableStateOf("") }
        private set

    // Complex state with custom saver
    var filters by savedStateHandle.saveable(
        stateSaver = FiltersSaver
    ) { mutableStateOf(SearchFilters()) }
        private set

    fun updateQuery(newQuery: String) {
        query = newQuery
        search()
    }
}

object FiltersSaver : Saver<SearchFilters, Bundle> {
    override fun save(value: SearchFilters): Bundle {
        return bundleOf(
            "category" to value.category,
            "minPrice" to value.minPrice,
            "maxPrice" to value.maxPrice
        )
    }

    override fun restore(value: Bundle): SearchFilters {
        return SearchFilters(
            category = value.getString("category"),
            minPrice = value.getFloat("minPrice"),
            maxPrice = value.getFloat("maxPrice")
        )
    }
}
```
