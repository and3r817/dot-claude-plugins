# Android Kotlin Coroutines Skill

Expert guidance for Android development using Kotlin Coroutines and Flow for asynchronous programming with structured
concurrency.

## Installation

```bash
/plugin marketplace add and3r817/dot-claude-plugins
/plugin install android-kotlin-coroutines@dot-claude-plugins
```

## What It Does

This skill provides comprehensive guidance for asynchronous Android development:

- **Coroutine Scopes**: viewModelScope, lifecycleScope, custom scopes with SupervisorJob
- **Flow Patterns**: StateFlow, SharedFlow, callbackFlow, flow operators
- **Error Handling**: Result pattern, CancellationException handling, CoroutineExceptionHandler
- **Testing**: runTest, Turbine, TestDispatcher, MainDispatcherRule

## Example Usage

Ask Claude:

- "How do I convert a callback API to a suspend function?"
- "Implement search with debounce using StateFlow"
- "Set up coroutine testing with Turbine"
- "Create an offline-first repository with Room and Flow"

## Coverage

| Topic            | Patterns                                              |
|------------------|-------------------------------------------------------|
| **Scopes**       | viewModelScope, lifecycleScope, SupervisorJob         |
| **Suspend**      | withContext, async/await, suspendCancellableCoroutine |
| **Flow**         | StateFlow, SharedFlow, callbackFlow, stateIn, shareIn |
| **Operators**    | flatMapLatest, combine, debounce, retry, catch        |
| **Testing**      | runTest, Turbine, TestDispatcher, MainDispatcherRule  |
| **Integrations** | Retrofit, Room, WorkManager, Firebase, DataStore      |

## Resources

- [Kotlin Coroutines Guide](https://kotlinlang.org/docs/coroutines-guide.html)
- [Android Coroutines Best Practices](https://developer.android.com/kotlin/coroutines/coroutines-best-practices)
- [Flow API Reference](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/)
