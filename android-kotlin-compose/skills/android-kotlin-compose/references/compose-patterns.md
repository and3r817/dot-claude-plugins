# Advanced Compose Patterns

Deep reference for advanced Jetpack Compose patterns, performance optimization, and custom implementations.

## Performance Optimization

### Stability and Recomposition

```kotlin
// UNSTABLE: List triggers recomposition even when contents unchanged
data class UserListState(
    val users: List<User>  // List is unstable
)

// STABLE: Use immutable collections
@Immutable
data class UserListState(
    val users: ImmutableList<User>  // From kotlinx.collections.immutable
)

// Or mark as stable if you guarantee immutability
@Stable
class UserListState(users: List<User>) {
    val users: List<User> = users.toList()  // Defensive copy
}
```

### Skippable Composables

```kotlin
// Enable strong skipping in gradle.properties
// android.compose.compiler.strong.skipping=true

// Ensure parameters are stable for skipping
@Composable
fun UserCard(
    user: User,                          // Must be @Stable or @Immutable
    onClick: () -> Unit,                 // Lambdas are stable
    modifier: Modifier = Modifier        // Modifier is stable
) {
    // This composable can be skipped if user hasn't changed
}

// Use remember for lambda stability when needed
@Composable
fun ParentComposable(viewModel: ViewModel) {
    val onClick = remember(viewModel) {
        { viewModel.onUserClick() }
    }
    UserCard(user = user, onClick = onClick)
}
```

### Deferred Reading

```kotlin
// BAD: Reads scroll state during composition
@Composable
fun BadScrollHeader(scrollState: ScrollState) {
    val alpha = 1f - (scrollState.value / 100f).coerceIn(0f, 1f)
    Header(alpha = alpha)  // Recomposes on every scroll pixel
}

// GOOD: Defer reading to layout/draw phase
@Composable
fun GoodScrollHeader(scrollState: ScrollState) {
    Header(
        modifier = Modifier.graphicsLayer {
            alpha = 1f - (scrollState.value / 100f).coerceIn(0f, 1f)
        }
    )
}

// GOOD: Use derivedStateOf for expensive computations
@Composable
fun FilteredList(items: List<Item>, query: String) {
    val filteredItems by remember(items, query) {
        derivedStateOf {
            items.filter { it.name.contains(query, ignoreCase = true) }
        }
    }
    LazyColumn {
        items(filteredItems, key = { it.id }) { item ->
            ItemRow(item)
        }
    }
}
```

### LazyColumn Optimization

```kotlin
@Composable
fun OptimizedList(items: ImmutableList<Item>) {
    LazyColumn {
        items(
            items = items,
            key = { it.id },  // CRITICAL: Enable item reuse
            contentType = { it.type }  // Group similar items
        ) { item ->
            // Use stable composables
            when (item.type) {
                ItemType.HEADER -> HeaderItem(item)
                ItemType.CONTENT -> ContentItem(item)
            }
        }
    }
}

// Avoid: Anonymous lambdas that change identity
LazyColumn {
    items(items) { item ->
        ItemRow(
            item = item,
            onClick = { viewModel.select(item) }  // New lambda each recomposition
        )
    }
}

// Better: Remember or hoist callbacks
LazyColumn {
    items(items, key = { it.id }) { item ->
        val onClick = remember(item.id) {
            { viewModel.select(item.id) }
        }
        ItemRow(item = item, onClick = onClick)
    }
}
```

## Custom Layouts

### Basic Custom Layout

```kotlin
@Composable
fun CustomRow(
    modifier: Modifier = Modifier,
    spacing: Dp = 8.dp,
    content: @Composable () -> Unit
) {
    Layout(
        content = content,
        modifier = modifier
    ) { measurables, constraints ->
        val spacingPx = spacing.roundToPx()

        // Measure children
        val placeables = measurables.map { measurable ->
            measurable.measure(constraints.copy(minWidth = 0))
        }

        // Calculate total width
        val totalWidth = placeables.sumOf { it.width } +
            (placeables.size - 1) * spacingPx
        val height = placeables.maxOfOrNull { it.height } ?: 0

        layout(totalWidth, height) {
            var xPosition = 0
            placeables.forEach { placeable ->
                placeable.placeRelative(x = xPosition, y = 0)
                xPosition += placeable.width + spacingPx
            }
        }
    }
}
```

### Intrinsic Measurements

```kotlin
@Composable
fun TwoColumnLayout(
    modifier: Modifier = Modifier,
    left: @Composable () -> Unit,
    right: @Composable () -> Unit
) {
    Layout(
        content = {
            Box { left() }
            Box { right() }
        },
        modifier = modifier
    ) { measurables, constraints ->
        // Support intrinsic height queries
        val leftMeasurable = measurables[0]
        val rightMeasurable = measurables[1]

        val leftWidth = constraints.maxWidth / 2
        val rightWidth = constraints.maxWidth - leftWidth

        val leftPlaceable = leftMeasurable.measure(
            constraints.copy(minWidth = leftWidth, maxWidth = leftWidth)
        )
        val rightPlaceable = rightMeasurable.measure(
            constraints.copy(minWidth = rightWidth, maxWidth = rightWidth)
        )

        val height = maxOf(leftPlaceable.height, rightPlaceable.height)

        layout(constraints.maxWidth, height) {
            leftPlaceable.placeRelative(0, 0)
            rightPlaceable.placeRelative(leftWidth, 0)
        }
    }
}
```

### SubcomposeLayout for Dynamic Content

```kotlin
@Composable
fun MeasureUnconstrainedContent(
    content: @Composable () -> Unit,
    measuredContent: @Composable (Size) -> Unit
) {
    SubcomposeLayout { constraints ->
        // First pass: measure content without constraints
        val measuredSize = subcompose("measure") {
            content()
        }.map { it.measure(Constraints()) }
            .fold(IntSize.Zero) { acc, placeable ->
                IntSize(
                    maxOf(acc.width, placeable.width),
                    maxOf(acc.height, placeable.height)
                )
            }

        // Second pass: compose with measured size
        val contentPlaceables = subcompose("content") {
            measuredContent(
                Size(
                    measuredSize.width.toDp().value,
                    measuredSize.height.toDp().value
                )
            )
        }.map { it.measure(constraints) }

        layout(constraints.maxWidth, constraints.maxHeight) {
            contentPlaceables.forEach { it.placeRelative(0, 0) }
        }
    }
}
```

## Animations

### Animate*AsState

```kotlin
@Composable
fun AnimatedVisibilityCard(isExpanded: Boolean) {
    val height by animateDpAsState(
        targetValue = if (isExpanded) 200.dp else 80.dp,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "card_height"
    )

    val alpha by animateFloatAsState(
        targetValue = if (isExpanded) 1f else 0.6f,
        animationSpec = tween(300),
        label = "card_alpha"
    )

    Card(
        modifier = Modifier
            .height(height)
            .alpha(alpha)
    ) { /* content */ }
}
```

### Transition API

```kotlin
enum class CardState { Collapsed, Expanded }

@Composable
fun TransitionCard(isExpanded: Boolean) {
    val transition = updateTransition(
        targetState = if (isExpanded) CardState.Expanded else CardState.Collapsed,
        label = "card_transition"
    )

    val height by transition.animateDp(
        label = "height",
        transitionSpec = {
            when {
                CardState.Collapsed isTransitioningTo CardState.Expanded ->
                    spring(stiffness = Spring.StiffnessLow)
                else -> spring(stiffness = Spring.StiffnessMedium)
            }
        }
    ) { state ->
        when (state) {
            CardState.Collapsed -> 80.dp
            CardState.Expanded -> 200.dp
        }
    }

    val cornerRadius by transition.animateDp(label = "corner") { state ->
        when (state) {
            CardState.Collapsed -> 16.dp
            CardState.Expanded -> 8.dp
        }
    }

    Card(
        modifier = Modifier.height(height),
        shape = RoundedCornerShape(cornerRadius)
    ) { /* content */ }
}
```

### Infinite Animations

```kotlin
@Composable
fun PulsingIndicator() {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")

    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )

    Box(
        modifier = Modifier
            .scale(scale)
            .size(24.dp)
            .background(Color.Red, CircleShape)
    )
}
```

### AnimatedContent

```kotlin
@Composable
fun AnimatedCounter(count: Int) {
    AnimatedContent(
        targetState = count,
        transitionSpec = {
            if (targetState > initialState) {
                slideInVertically { -it } + fadeIn() togetherWith
                    slideOutVertically { it } + fadeOut()
            } else {
                slideInVertically { it } + fadeIn() togetherWith
                    slideOutVertically { -it } + fadeOut()
            }.using(SizeTransform(clip = false))
        },
        label = "counter"
    ) { targetCount ->
        Text(
            text = "$targetCount",
            style = MaterialTheme.typography.displayLarge
        )
    }
}
```

## Gestures and Touch

### Combined Gestures

```kotlin
@Composable
fun ZoomableImage(painter: Painter) {
    var scale by remember { mutableFloatStateOf(1f) }
    var offset by remember { mutableStateOf(Offset.Zero) }

    val state = rememberTransformableState { zoomChange, panChange, _ ->
        scale = (scale * zoomChange).coerceIn(0.5f, 3f)
        offset += panChange
    }

    Image(
        painter = painter,
        contentDescription = null,
        modifier = Modifier
            .transformable(state)
            .graphicsLayer {
                scaleX = scale
                scaleY = scale
                translationX = offset.x
                translationY = offset.y
            }
    )
}
```

### Drag and Drop

```kotlin
@Composable
fun DraggableItem(
    onDragEnd: (Offset) -> Unit
) {
    var offsetX by remember { mutableFloatStateOf(0f) }
    var offsetY by remember { mutableFloatStateOf(0f) }

    Box(
        modifier = Modifier
            .offset { IntOffset(offsetX.roundToInt(), offsetY.roundToInt()) }
            .pointerInput(Unit) {
                detectDragGestures(
                    onDragEnd = {
                        onDragEnd(Offset(offsetX, offsetY))
                    }
                ) { change, dragAmount ->
                    change.consume()
                    offsetX += dragAmount.x
                    offsetY += dragAmount.y
                }
            }
            .size(100.dp)
            .background(Color.Blue)
    )
}
```

### Nested Scrolling

```kotlin
@Composable
fun NestedScrollExample() {
    val nestedScrollConnection = remember {
        object : NestedScrollConnection {
            override fun onPreScroll(available: Offset, source: NestedScrollSource): Offset {
                // Consume scroll before children
                return Offset.Zero
            }

            override fun onPostScroll(
                consumed: Offset,
                available: Offset,
                source: NestedScrollSource
            ): Offset {
                // Handle scroll after children
                return Offset.Zero
            }
        }
    }

    Box(
        modifier = Modifier.nestedScroll(nestedScrollConnection)
    ) {
        LazyColumn {
            // Content
        }
    }
}
```

## CompositionLocal

### Creating Custom CompositionLocals

```kotlin
// Define
val LocalUserSession = compositionLocalOf<UserSession?> { null }
val LocalAnalytics = staticCompositionLocalOf<Analytics> {
    error("Analytics not provided")
}

// Provide
@Composable
fun AppRoot(
    userSession: UserSession?,
    analytics: Analytics
) {
    CompositionLocalProvider(
        LocalUserSession provides userSession,
        LocalAnalytics provides analytics
    ) {
        AppContent()
    }
}

// Consume
@Composable
fun UserGreeting() {
    val session = LocalUserSession.current
    val analytics = LocalAnalytics.current

    if (session != null) {
        Text("Welcome, ${session.userName}")
        LaunchedEffect(Unit) {
            analytics.trackEvent("greeting_shown")
        }
    }
}
```

## Testing Compose

### UI Testing

```kotlin
@get:Rule
val composeTestRule = createComposeRule()

@Test
fun counterIncrementsOnClick() {
    composeTestRule.setContent {
        CounterScreen()
    }

    // Find and verify
    composeTestRule
        .onNodeWithText("Count: 0")
        .assertIsDisplayed()

    // Interact
    composeTestRule
        .onNodeWithContentDescription("Increment")
        .performClick()

    // Verify change
    composeTestRule
        .onNodeWithText("Count: 1")
        .assertIsDisplayed()
}

@Test
fun listShowsAllItems() {
    val items = listOf("Item 1", "Item 2", "Item 3")

    composeTestRule.setContent {
        ItemList(items = items)
    }

    items.forEach { item ->
        composeTestRule
            .onNodeWithText(item)
            .assertIsDisplayed()
    }
}
```

### Screenshot Testing

```kotlin
@get:Rule
val composeTestRule = createComposeRule()

@Test
fun buttonMatchesGolden() {
    composeTestRule.setContent {
        PrimaryButton(text = "Click Me", onClick = {})
    }

    composeTestRule
        .onNodeWithText("Click Me")
        .captureToImage()
        .assertAgainstGolden("primary_button")
}
```

## Accessibility

```kotlin
@Composable
fun AccessibleCard(
    title: String,
    description: String,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .semantics(mergeDescendants = true) {
                contentDescription = "$title. $description"
                role = Role.Button
            }
            .clickable(
                onClick = onClick,
                onClickLabel = "Open $title"
            )
    ) {
        Column {
            Text(
                text = title,
                modifier = Modifier.semantics { heading() }
            )
            Text(text = description)
        }
    }
}

@Composable
fun AccessibleToggle(
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    label: String
) {
    Row(
        modifier = Modifier
            .toggleable(
                value = checked,
                onValueChange = onCheckedChange,
                role = Role.Switch
            )
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            modifier = Modifier.weight(1f)
        )
        Switch(
            checked = checked,
            onCheckedChange = null  // Handled by row
        )
    }
}
```
