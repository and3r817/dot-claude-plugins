# Testing Coroutines

Comprehensive guide for testing suspend functions, Flows, and coroutine-based code in Android.

## Setup

### Dependencies

```kotlin
// build.gradle.kts
testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.8.0")
testImplementation("app.cash.turbine:turbine:1.0.0")
testImplementation("io.mockk:mockk:1.13.9")
testImplementation("com.google.truth:truth:1.4.0")
```

## Testing Suspend Functions

### Basic runTest Usage

```kotlin
class UserRepositoryTest {

    private lateinit var repository: UserRepository
    private val api: UserApi = mockk()

    @Before
    fun setup() {
        repository = UserRepository(api, StandardTestDispatcher())
    }

    @Test
    fun `getUser returns user on success`() = runTest {
        // Given
        val expectedUser = User(id = "1", name = "John")
        coEvery { api.getUser("1") } returns expectedUser

        // When
        val result = repository.getUser("1")

        // Then
        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()).isEqualTo(expectedUser)
    }

    @Test
    fun `getUser returns failure on error`() = runTest {
        // Given
        coEvery { api.getUser("1") } throws IOException("Network error")

        // When
        val result = repository.getUser("1")

        // Then
        assertThat(result.isFailure).isTrue()
        assertThat(result.exceptionOrNull()).isInstanceOf(IOException::class.java)
    }
}
```

### Testing Timeouts

```kotlin
@Test
fun `operation times out after 5 seconds`() = runTest {
    val result = withTimeoutOrNull(5000) {
        // This will be skipped in virtual time
        delay(10000)
        "completed"
    }

    assertThat(result).isNull()
}
```

### Advancing Virtual Time

```kotlin
@Test
fun `debounce waits correct duration`() = runTest {
    val values = mutableListOf<Int>()
    val flow = MutableSharedFlow<Int>()

    backgroundScope.launch {
        flow.debounce(1000).collect { values.add(it) }
    }

    flow.emit(1)
    advanceTimeBy(500)
    flow.emit(2)
    advanceTimeBy(500)
    flow.emit(3)
    advanceTimeBy(1000)

    assertThat(values).containsExactly(3)
}
```

## Testing ViewModels

### Basic ViewModel Test

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class UserViewModelTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private lateinit var viewModel: UserViewModel
    private val repository: UserRepository = mockk()

    @Before
    fun setup() {
        viewModel = UserViewModel(repository)
    }

    @Test
    fun `loadUser updates state to success`() = runTest {
        // Given
        val user = User(id = "1", name = "John")
        coEvery { repository.getUser() } returns Result.success(user)

        // When
        viewModel.loadUser()

        // Then
        val state = viewModel.uiState.value
        assertThat(state.isLoading).isFalse()
        assertThat(state.user).isEqualTo(user)
        assertThat(state.error).isNull()
    }
}
```

### MainDispatcherRule

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class MainDispatcherRule(
    private val testDispatcher: TestDispatcher = UnconfinedTestDispatcher()
) : TestWatcher() {

    override fun starting(description: Description) {
        Dispatchers.setMain(testDispatcher)
    }

    override fun finished(description: Description) {
        Dispatchers.resetMain()
    }
}
```

### Testing StateFlow with Turbine

```kotlin
@Test
fun `uiState emits loading then success`() = runTest {
    val user = User(id = "1", name = "John")
    coEvery { repository.getUser() } coAnswers {
        delay(100)
        Result.success(user)
    }

    viewModel.uiState.test {
        // Initial state
        assertThat(awaitItem().isLoading).isFalse()

        viewModel.loadUser()

        // Loading state
        assertThat(awaitItem().isLoading).isTrue()

        // Success state
        val successState = awaitItem()
        assertThat(successState.isLoading).isFalse()
        assertThat(successState.user).isEqualTo(user)

        cancelAndIgnoreRemainingEvents()
    }
}
```

## Testing Flows with Turbine

### Basic Flow Testing

```kotlin
@Test
fun `repository emits values correctly`() = runTest {
    val flow = repository.getUserUpdates("1")

    flow.test {
        assertThat(awaitItem()).isEqualTo(User(id = "1", name = "Initial"))
        assertThat(awaitItem()).isEqualTo(User(id = "1", name = "Updated"))
        awaitComplete()
    }
}
```

### Testing Error Scenarios

```kotlin
@Test
fun `flow emits error on failure`() = runTest {
    coEvery { api.streamData() } returns flow {
        emit(Data(1))
        throw IOException("Connection lost")
    }

    repository.dataStream().test {
        assertThat(awaitItem()).isEqualTo(Data(1))

        val error = awaitError()
        assertThat(error).isInstanceOf(IOException::class.java)
        assertThat(error.message).isEqualTo("Connection lost")
    }
}
```

### Testing SharedFlow Events

```kotlin
@Test
fun `event is emitted on action`() = runTest {
    viewModel.events.test {
        viewModel.submitOrder(order)

        val event = awaitItem()
        assertThat(event).isInstanceOf(OrderEvent.Success::class.java)

        expectNoEvents()
    }
}
```

### Turbine Timeout Configuration

```kotlin
@Test
fun `handles slow emissions`() = runTest {
    slowFlow.test(timeout = 10.seconds) {
        awaitItem()  // Will wait up to 10 seconds
        cancelAndIgnoreRemainingEvents()
    }
}
```

## Testing with Test Dispatchers

### StandardTestDispatcher vs UnconfinedTestDispatcher

```kotlin
// StandardTestDispatcher: requires explicit time advancement
@Test
fun `with standard dispatcher`() = runTest {
    val testDispatcher = StandardTestDispatcher(testScheduler)
    val repository = Repository(testDispatcher)

    val deferred = async { repository.fetchData() }

    // Must advance time for coroutines to execute
    advanceUntilIdle()

    assertThat(deferred.await()).isNotNull()
}

// UnconfinedTestDispatcher: immediate execution
@Test
fun `with unconfined dispatcher`() = runTest {
    val testDispatcher = UnconfinedTestDispatcher(testScheduler)
    val repository = Repository(testDispatcher)

    // Executes immediately, no time advancement needed
    val result = repository.fetchData()

    assertThat(result).isNotNull()
}
```

### Injecting Test Dispatchers

```kotlin
class UserRepository(
    private val api: UserApi,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) {
    suspend fun getUser(id: String): User = withContext(ioDispatcher) {
        api.getUser(id)
    }
}

@Test
fun `repository uses injected dispatcher`() = runTest {
    val testDispatcher = StandardTestDispatcher(testScheduler)
    val repository = UserRepository(api, testDispatcher)

    repository.getUser("1")

    // Verify dispatcher was used
    coVerify { api.getUser("1") }
}
```

## Testing Coroutine Cancellation

### Verifying Cancellation Handling

```kotlin
@Test
fun `cancellation cleans up resources`() = runTest {
    var cleanedUp = false

    val job = launch {
        try {
            delay(Long.MAX_VALUE)
        } finally {
            cleanedUp = true
        }
    }

    job.cancel()
    job.join()

    assertThat(cleanedUp).isTrue()
}
```

### Testing suspendCancellableCoroutine

```kotlin
@Test
fun `callback is unregistered on cancellation`() = runTest {
    var unregistered = false

    val job = launch {
        suspendCancellableCoroutine<Unit> { cont ->
            cont.invokeOnCancellation {
                unregistered = true
            }
        }
    }

    job.cancel()
    advanceUntilIdle()

    assertThat(unregistered).isTrue()
}
```

## Testing Concurrent Operations

### Testing Parallel Execution

```kotlin
@Test
fun `fetches user and posts in parallel`() = runTest {
    val userDelay = 100L
    val postsDelay = 150L

    coEvery { api.getUser("1") } coAnswers {
        delay(userDelay)
        User(id = "1")
    }
    coEvery { api.getPosts("1") } coAnswers {
        delay(postsDelay)
        listOf(Post(id = "1"))
    }

    val startTime = currentTime
    val result = repository.getUserWithPosts("1")
    val endTime = currentTime

    // Should complete in max(userDelay, postsDelay), not sum
    assertThat(endTime - startTime).isEqualTo(postsDelay)
    assertThat(result.user).isNotNull()
    assertThat(result.posts).hasSize(1)
}
```

### Testing Race Conditions

```kotlin
@Test
fun `only latest search result is used`() = runTest {
    val results = mutableListOf<String>()

    val searchFlow = MutableSharedFlow<String>()
    val job = launch {
        searchFlow
            .flatMapLatest { query ->
                flow {
                    delay(100)
                    emit("Result for: $query")
                }
            }
            .collect { results.add(it) }
    }

    searchFlow.emit("A")
    advanceTimeBy(50)
    searchFlow.emit("B")  // Should cancel "A"
    advanceTimeBy(150)

    assertThat(results).containsExactly("Result for: B")

    job.cancel()
}
```

## Testing with Fakes

### Fake Repository Pattern

```kotlin
class FakeUserRepository : UserRepository {
    var users = mutableMapOf<String, User>()
    var shouldFail = false
    var delayMs = 0L

    override suspend fun getUser(id: String): Result<User> {
        if (delayMs > 0) delay(delayMs)
        if (shouldFail) return Result.failure(IOException("Fake error"))
        return users[id]?.let { Result.success(it) }
            ?: Result.failure(NoSuchElementException())
    }

    override fun observeUser(id: String): Flow<User> = flow {
        while (true) {
            users[id]?.let { emit(it) }
            delay(100)
        }
    }
}

@Test
fun `viewModel handles repository error`() = runTest {
    val fakeRepository = FakeUserRepository().apply {
        shouldFail = true
    }
    val viewModel = UserViewModel(fakeRepository)

    viewModel.loadUser("1")

    assertThat(viewModel.uiState.value.error).isNotNull()
}
```

## Integration Testing

### Testing Room with Coroutines

```kotlin
@RunWith(AndroidJUnit4::class)
class UserDaoTest {

    private lateinit var database: AppDatabase
    private lateinit var userDao: UserDao

    @Before
    fun setup() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            AppDatabase::class.java
        ).build()
        userDao = database.userDao()
    }

    @After
    fun teardown() {
        database.close()
    }

    @Test
    fun insertAndRetrieveUser() = runTest {
        val user = UserEntity(id = "1", name = "John")

        userDao.insert(user)
        val retrieved = userDao.getUser("1").first()

        assertThat(retrieved).isEqualTo(user)
    }

    @Test
    fun observeUserUpdates() = runTest {
        userDao.observeUser("1").test {
            assertThat(awaitItem()).isNull()

            userDao.insert(UserEntity(id = "1", name = "John"))
            assertThat(awaitItem()?.name).isEqualTo("John")

            userDao.insert(UserEntity(id = "1", name = "Jane"))
            assertThat(awaitItem()?.name).isEqualTo("Jane")

            cancelAndIgnoreRemainingEvents()
        }
    }
}
```

## Best Practices

### Test Organization

```kotlin
class ViewModelTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    // Use backgroundScope for long-running collections
    @Test
    fun `state updates correctly`() = runTest {
        backgroundScope.launch {
            viewModel.uiState.collect { /* observe */ }
        }

        viewModel.performAction()

        // Assert immediately after action
        assertThat(viewModel.uiState.value.done).isTrue()
    }
}
```

### Avoiding Flaky Tests

```kotlin
// BAD: Timing-dependent
@Test
fun `flaky test`() = runTest {
    viewModel.loadData()
    delay(100)  // Hope it's done
    assertThat(viewModel.data).isNotNull()
}

// GOOD: Use Turbine or explicit waits
@Test
fun `reliable test`() = runTest {
    viewModel.uiState.test {
        skipItems(1)  // Skip initial
        viewModel.loadData()
        val state = awaitItem()
        assertThat(state.data).isNotNull()
    }
}
```
