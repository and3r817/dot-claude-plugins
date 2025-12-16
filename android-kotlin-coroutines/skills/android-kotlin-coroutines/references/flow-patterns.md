# Advanced Flow Patterns

Deep reference for Kotlin Flow operations, sharing strategies, and advanced reactive patterns.

## Hot vs Cold Flows

### Cold Flows

```kotlin
// Cold: new execution for each collector
fun getData(): Flow<Data> = flow {
    val data = api.fetchData()  // Runs each time
    emit(data)
}

// Both collectors trigger separate API calls
coroutineScope {
    launch { getData().collect { println("Collector 1: $it") } }
    launch { getData().collect { println("Collector 2: $it") } }
}
```

### Hot Flows (StateFlow, SharedFlow)

```kotlin
// Hot: single execution, multiple observers
class DataRepository {
    private val _data = MutableStateFlow<Data?>(null)
    val data: StateFlow<Data?> = _data.asStateFlow()

    suspend fun refresh() {
        _data.value = api.fetchData()  // Single API call
    }
}

// Both collectors share the same emission
coroutineScope {
    launch { repository.data.collect { println("Collector 1: $it") } }
    launch { repository.data.collect { println("Collector 2: $it") } }
}
```

## Sharing Strategies

### stateIn vs shareIn

```kotlin
// StateFlow: always has current value, replay = 1
val uiState: StateFlow<UiState> = repository.dataFlow
    .map { UiState.Success(it) }
    .stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = UiState.Loading
    )

// SharedFlow: configurable replay, no initial value required
val events: SharedFlow<Event> = repository.eventFlow
    .shareIn(
        scope = viewModelScope,
        started = SharingStarted.Lazily,
        replay = 0  // Events not replayed to new subscribers
    )
```

### SharingStarted Options

```kotlin
// Eagerly: start immediately, never stop
val eager = flow.stateIn(
    scope = viewModelScope,
    started = SharingStarted.Eagerly,
    initialValue = initial
)

// Lazily: start on first subscriber, never stop
val lazy = flow.stateIn(
    scope = viewModelScope,
    started = SharingStarted.Lazily,
    initialValue = initial
)

// WhileSubscribed: start/stop based on subscribers
val whileSubscribed = flow.stateIn(
    scope = viewModelScope,
    started = SharingStarted.WhileSubscribed(
        stopTimeoutMillis = 5000,      // Wait 5s after last subscriber
        replayExpirationMillis = 0     // Keep replay cache forever
    ),
    initialValue = initial
)
```

## Flow Transformation Operators

### flatMapLatest vs flatMapConcat vs flatMapMerge

```kotlin
// flatMapLatest: cancel previous flow when new value arrives
val searchResults = searchQuery
    .debounce(300)
    .flatMapLatest { query ->
        repository.search(query)  // Previous search cancelled
    }

// flatMapConcat: wait for each flow to complete sequentially
val sequentialResults = ids.asFlow()
    .flatMapConcat { id ->
        repository.fetchDetails(id)  // Waits for completion
    }

// flatMapMerge: concurrent execution up to concurrency limit
val concurrentResults = ids.asFlow()
    .flatMapMerge(concurrency = 4) { id ->
        repository.fetchDetails(id)  // Up to 4 concurrent
    }
```

### transformLatest

```kotlin
// Complex transformation with cancellation
val processedData = rawData
    .transformLatest { data ->
        emit(ProcessingState.Loading)
        try {
            val processed = processData(data)  // Cancelled if new data arrives
            emit(ProcessingState.Success(processed))
        } catch (e: Exception) {
            emit(ProcessingState.Error(e))
        }
    }
```

### scan and runningFold

```kotlin
// Accumulate values over time
val runningTotal = transactionFlow
    .scan(0) { acc, transaction ->
        acc + transaction.amount
    }

// Alternative with initial value handling
val history = eventFlow
    .runningFold(emptyList<Event>()) { acc, event ->
        acc + event
    }
```

## Combining Flows

### combine vs zip

```kotlin
// combine: emit whenever ANY source emits (uses latest from each)
val combined = combine(
    userFlow,
    settingsFlow,
    notificationsFlow
) { user, settings, notifications ->
    DashboardState(user, settings, notifications)
}

// zip: emit only when ALL sources have new values (pairs up)
val paired = userFlow.zip(metadataFlow) { user, metadata ->
    UserWithMetadata(user, metadata)
}
```

### merge

```kotlin
// Merge multiple flows into one
val allEvents = merge(
    networkEvents,
    databaseEvents,
    userInputEvents
)
```

### combineTransform

```kotlin
// Complex combination logic
val result = combineTransform(
    userFlow,
    permissionsFlow
) { user, permissions ->
    if (permissions.canView) {
        emit(ViewState.Visible(user))
    } else {
        emit(ViewState.Hidden)
    }
}
```

## Buffering and Conflation

### buffer

```kotlin
// Buffer emissions to handle slow collectors
val buffered = heavyProducer
    .buffer(capacity = 64, onBufferOverflow = BufferOverflow.DROP_OLDEST)
    .collect { value ->
        slowProcess(value)
    }
```

### conflate

```kotlin
// Keep only the latest value when collector is slow
val conflated = rapidUpdates
    .conflate()
    .collect { value ->
        updateUI(value)  // May skip intermediate values
    }
```

### collectLatest

```kotlin
// Cancel previous collection when new value arrives
rapidUpdates
    .collectLatest { value ->
        val result = expensiveOperation(value)  // Cancelled if new value
        updateUI(result)
    }
```

## Error Handling

### catch

```kotlin
val safeFlow = repository.dataFlow
    .map { transform(it) }
    .catch { e ->
        emit(fallbackValue)
        // Or: emit error state
        // Or: just log and complete
    }
```

### retryWhen

```kotlin
fun <T> Flow<T>.retryWithExponentialBackoff(
    maxRetries: Int = 3,
    initialDelayMs: Long = 1000,
    maxDelayMs: Long = 30000,
    factor: Double = 2.0
): Flow<T> = retryWhen { cause, attempt ->
    if (attempt < maxRetries && cause is IOException) {
        val delayMs = (initialDelayMs * factor.pow(attempt.toDouble()))
            .toLong()
            .coerceAtMost(maxDelayMs)
        delay(delayMs)
        true
    } else {
        false
    }
}
```

### onCompletion

```kotlin
val flow = dataFlow
    .onCompletion { cause ->
        if (cause != null) {
            logError(cause)
        }
        cleanup()
    }
```

## Channel-Based Patterns

### channelFlow vs callbackFlow

```kotlin
// channelFlow: for concurrent emissions from coroutines
fun multiSourceData(): Flow<Data> = channelFlow {
    launch {
        source1.getData().collect { send(it) }
    }
    launch {
        source2.getData().collect { send(it) }
    }
}

// callbackFlow: for callback-based APIs
fun locationUpdates(): Flow<Location> = callbackFlow {
    val callback = LocationCallback { location ->
        trySend(location)
    }
    registerCallback(callback)
    awaitClose { unregisterCallback(callback) }
}
```

### produceIn

```kotlin
// Convert Flow to ReceiveChannel for select
val channel = dataFlow.produceIn(scope)

select {
    channel.onReceive { data ->
        process(data)
    }
    timeoutChannel.onReceive {
        handleTimeout()
    }
}
```

## Lifecycle-Aware Collection

### repeatOnLifecycle

```kotlin
// In Activity/Fragment
lifecycleScope.launch {
    repeatOnLifecycle(Lifecycle.State.STARTED) {
        // Collect only when STARTED or above
        // Automatically cancelled when below STARTED
        viewModel.uiState.collect { state ->
            updateUI(state)
        }
    }
}
```

### flowWithLifecycle

```kotlin
// Apply lifecycle awareness to a single flow
lifecycleScope.launch {
    viewModel.uiState
        .flowWithLifecycle(lifecycle, Lifecycle.State.STARTED)
        .collect { state ->
            updateUI(state)
        }
}
```

## Custom Flow Operators

### Creating Custom Operators

```kotlin
// Extension function for throttle first
fun <T> Flow<T>.throttleFirst(periodMillis: Long): Flow<T> = flow {
    var lastEmitTime = 0L
    collect { value ->
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastEmitTime >= periodMillis) {
            lastEmitTime = currentTime
            emit(value)
        }
    }
}

// Distinct until changed with custom comparator
fun <T> Flow<T>.distinctUntilChangedBy(
    selector: (T) -> Any?
): Flow<T> = distinctUntilChanged { old, new ->
    selector(old) == selector(new)
}
```

### Flow with Resources

```kotlin
// Ensure resource cleanup
fun databaseQuery(query: String): Flow<List<Row>> = flow {
    val connection = database.openConnection()
    try {
        val cursor = connection.execute(query)
        while (cursor.hasNext()) {
            emit(cursor.next())
        }
    } finally {
        connection.close()
    }
}
```

## Performance Considerations

### flowOn placement

```kotlin
// CORRECT: flowOn affects upstream only
val flow = repository.heavyDataFlow     // Runs on IO
    .map { transform(it) }               // Runs on IO
    .flowOn(Dispatchers.IO)              // Switch point
    .map { formatForUI(it) }             // Runs on collector's dispatcher

// AVOID: Multiple flowOn calls
val inefficient = flow
    .map { step1(it) }
    .flowOn(Dispatchers.IO)
    .map { step2(it) }
    .flowOn(Dispatchers.Default)  // Creates extra dispatching
```

### Avoiding Redundant Collections

```kotlin
// BAD: Collects twice
viewModelScope.launch {
    repository.dataFlow.collect { /* use 1 */ }
}
viewModelScope.launch {
    repository.dataFlow.collect { /* use 2 */ }
}

// GOOD: Share the flow
val sharedFlow = repository.dataFlow.shareIn(
    scope = viewModelScope,
    started = SharingStarted.WhileSubscribed(5000),
    replay = 1
)
```
