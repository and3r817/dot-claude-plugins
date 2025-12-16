# Jetpack Compose Animation Guide

Comprehensive reference for animations in Jetpack Compose, from fundamentals to advanced techniques.

## Animation API Stack

```
LOW-LEVEL (Manual control)
├── Animatable           // Single value animation with suspend functions
├── AnimationState       // Low-level animation state
└── AnimationSpec        // Animation curves/timing

MID-LEVEL (Common use cases)
├── animate*AsState      // Simple state-based animations
├── updateTransition     // Multi-property coordinated animations
├── AnimatedVisibility   // Enter/exit animations
└── AnimatedContent      // Content switching with transitions

HIGH-LEVEL (Complex scenarios)
├── Modifier.animateContentSize()  // Automatic size animations
├── rememberInfiniteTransition()   // Looping animations
└── CrossFade()                    // Fade between composables
```

## State-Based Animations

### animate*AsState (Most Common)

```kotlin
@Composable
fun PulsingHeart() {
    var isLiked by remember { mutableStateOf(false) }

    val scale by animateFloatAsState(
        targetValue = if (isLiked) 1.3f else 1.0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "heart_scale"
    )

    Icon(
        imageVector = Icons.Default.Favorite,
        contentDescription = null,
        modifier = Modifier
            .scale(scale)
            .clickable { isLiked = !isLiked }
    )
}
```

**Available animate*AsState functions:**

```kotlin
animateFloatAsState()      // Float values
animateDpAsState()         // Dp values
animateColorAsState()      // Color transitions
animateIntAsState()        // Int values
animateOffsetAsState()     // Offset positions
animateSizeAsState()       // Size values
animateIntOffsetAsState()  // IntOffset positions
animateIntSizeAsState()    // IntSize values
```

**When to use:** Single property animations, state-driven UI changes, simple interactive animations.

## Transition API (Coordinated Multi-Property)

```kotlin
@Composable
fun ExpandableCard() {
    var expanded by remember { mutableStateOf(false) }

    val transition = updateTransition(expanded, label = "card")

    val cardHeight by transition.animateDp(
        transitionSpec = { spring(dampingRatio = 0.7f) },
        label = "height"
    ) { isExpanded ->
        if (isExpanded) 400.dp else 100.dp
    }

    val cardElevation by transition.animateDp(
        transitionSpec = { tween(300) },
        label = "elevation"
    ) { isExpanded ->
        if (isExpanded) 24.dp else 4.dp
    }

    val iconRotation by transition.animateFloat(
        transitionSpec = { tween(300) },
        label = "rotation"
    ) { isExpanded ->
        if (isExpanded) 180f else 0f
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .height(cardHeight)
            .clickable { expanded = !expanded },
        elevation = CardDefaults.cardElevation(defaultElevation = cardElevation)
    ) {
        Column {
            Row(
                modifier = Modifier.padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Expandable Card", modifier = Modifier.weight(1f))
                Icon(
                    Icons.Default.KeyboardArrowDown,
                    contentDescription = null,
                    modifier = Modifier.rotate(iconRotation)
                )
            }

            if (expanded) {
                Text(
                    "Expanded content here...",
                    modifier = Modifier.padding(16.dp)
                )
            }
        }
    }
}
```

**When to use:** Multiple coordinated animations, complex state transitions, synchronized property changes.

## AnimatedVisibility (Enter/Exit)

```kotlin
@Composable
fun NotificationBanner() {
    var visible by remember { mutableStateOf(false) }

    Column {
        Button(onClick = { visible = !visible }) {
            Text("Toggle Notification")
        }

        AnimatedVisibility(
            visible = visible,
            enter = slideInVertically(
                initialOffsetY = { -it }
            ) + fadeIn(),
            exit = slideOutVertically(
                targetOffsetY = { -it }
            ) + fadeOut()
        ) {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            ) {
                Text(
                    "Important notification!",
                    modifier = Modifier.padding(16.dp)
                )
            }
        }
    }
}
```

### Built-in Enter/Exit Transitions

```kotlin
// Fade
fadeIn(animationSpec, initialAlpha)
fadeOut(animationSpec, targetAlpha)

// Slide
slideInHorizontally(animationSpec) { fullWidth -> initialOffsetX }
slideOutHorizontally(animationSpec) { fullWidth -> targetOffsetX }
slideInVertically(animationSpec) { fullHeight -> initialOffsetY }
slideOutVertically(animationSpec) { fullHeight -> targetOffsetY }

// Expand/Shrink
expandIn(animationSpec, expandFrom, clip, initialSize)
shrinkOut(animationSpec, shrinkTowards, clip, targetSize)
expandHorizontally(animationSpec, expandFrom, clip, initialWidth)
shrinkHorizontally(animationSpec, shrinkTowards, clip, targetWidth)
expandVertically(animationSpec, expandFrom, clip, initialHeight)
shrinkVertically(animationSpec, shrinkTowards, clip, targetHeight)

// Scale
scaleIn(animationSpec, initialScale, transformOrigin)
scaleOut(animationSpec, targetScale, transformOrigin)

// Combine transitions with +
fadeIn() + slideInVertically()
scaleIn() + expandIn()
```

### AnimatedVisibility with Child Animations

```kotlin
@Composable
fun StaggeredList() {
    var visible by remember { mutableStateOf(false) }

    AnimatedVisibility(
        visible = visible,
        enter = fadeIn()
    ) {
        Column {
            listOf("Item 1", "Item 2", "Item 3").forEachIndexed { index, item ->
                Text(
                    text = item,
                    modifier = Modifier
                        .animateEnterExit(
                            enter = slideInHorizontally(
                                animationSpec = tween(
                                    durationMillis = 300,
                                    delayMillis = index * 100
                                )
                            ) { -it }
                        )
                        .padding(8.dp)
                )
            }
        }
    }
}
```

## AnimatedContent (Content Switching)

```kotlin
@Composable
fun CounterWithAnimation() {
    var count by remember { mutableIntStateOf(0) }

    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        AnimatedContent(
            targetState = count,
            transitionSpec = {
                if (targetState > initialState) {
                    // Count up: slide up and fade
                    slideInVertically { height -> height } + fadeIn() togetherWith
                        slideOutVertically { height -> -height } + fadeOut()
                } else {
                    // Count down: slide down and fade
                    slideInVertically { height -> -height } + fadeIn() togetherWith
                        slideOutVertically { height -> height } + fadeOut()
                }.using(
                    SizeTransform(clip = false)
                )
            },
            label = "counter"
        ) { targetCount ->
            Text(
                text = "$targetCount",
                style = MaterialTheme.typography.displayLarge
            )
        }

        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            Button(onClick = { count-- }) { Text("-") }
            Button(onClick = { count++ }) { Text("+") }
        }
    }
}
```

### Tab Content Animation

```kotlin
@Composable
fun AnimatedTabContent(selectedTab: Int) {
    AnimatedContent(
        targetState = selectedTab,
        transitionSpec = {
            val direction = if (targetState > initialState) 1 else -1
            slideInHorizontally { width -> direction * width } + fadeIn() togetherWith
                slideOutHorizontally { width -> -direction * width } + fadeOut()
        },
        label = "tab_content"
    ) { tab ->
        when (tab) {
            0 -> HomeContent()
            1 -> ProfileContent()
            2 -> SettingsContent()
        }
    }
}
```

## Infinite Animations (Looping)

```kotlin
@Composable
fun LoadingSpinner() {
    val infiniteTransition = rememberInfiniteTransition(label = "spinner")

    val rotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "rotation"
    )

    val scale by infiniteTransition.animateFloat(
        initialValue = 0.8f,
        targetValue = 1.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(800, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scale"
    )

    Box(
        modifier = Modifier
            .size(48.dp)
            .scale(scale)
            .rotate(rotation),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator()
    }
}
```

### Pulsing Animation

```kotlin
@Composable
fun PulsingDot() {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")

    val alpha by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000),
            repeatMode = RepeatMode.Reverse
        ),
        label = "alpha"
    )

    val size by infiniteTransition.animateDp(
        initialValue = 8.dp,
        targetValue = 16.dp,
        animationSpec = infiniteRepeatable(
            animation = tween(1000),
            repeatMode = RepeatMode.Reverse
        ),
        label = "size"
    )

    Box(
        modifier = Modifier
            .size(size)
            .alpha(alpha)
            .background(Color.Red, CircleShape)
    )
}
```

## Gesture-Driven Animations

### Swipeable Card

```kotlin
@Composable
fun SwipeableCard(onDismiss: () -> Unit) {
    var offsetX by remember { mutableFloatStateOf(0f) }
    val animatedOffsetX by animateFloatAsState(
        targetValue = offsetX,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy
        ),
        label = "offset"
    )

    val dismissThreshold = 300f

    Card(
        modifier = Modifier
            .offset { IntOffset(animatedOffsetX.roundToInt(), 0) }
            .alpha(1f - (abs(animatedOffsetX) / 500f).coerceIn(0f, 1f))
            .pointerInput(Unit) {
                detectHorizontalDragGestures(
                    onDragEnd = {
                        offsetX = if (abs(offsetX) > dismissThreshold) {
                            if (offsetX > 0) 1000f else -1000f
                        } else {
                            0f
                        }
                        if (abs(offsetX) > dismissThreshold) {
                            onDismiss()
                        }
                    },
                    onHorizontalDrag = { _, dragAmount ->
                        offsetX += dragAmount
                    }
                )
            }
    ) {
        Text("Swipe me!", modifier = Modifier.padding(32.dp))
    }
}
```

### Draggable with Snap Points

```kotlin
@Composable
fun SnapDrawer() {
    val snapPoints = listOf(0f, 200f, 400f)
    var targetOffset by remember { mutableFloatStateOf(0f) }
    val offset by animateFloatAsState(
        targetValue = targetOffset,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioLowBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "drawer_offset"
    )

    Box(
        modifier = Modifier
            .offset { IntOffset(offset.roundToInt(), 0) }
            .pointerInput(Unit) {
                detectHorizontalDragGestures(
                    onDragEnd = {
                        // Snap to nearest point
                        targetOffset = snapPoints.minByOrNull {
                            abs(it - targetOffset)
                        } ?: 0f
                    },
                    onHorizontalDrag = { _, dragAmount ->
                        targetOffset = (targetOffset + dragAmount)
                            .coerceIn(snapPoints.first(), snapPoints.last())
                    }
                )
            }
            .width(300.dp)
            .fillMaxHeight()
            .background(Color.White)
    ) {
        // Drawer content
    }
}
```

## AnimationSpec Types

### Spring (Physics-Based)

```kotlin
// Default spring
spring<Float>()

// Custom spring parameters
spring(
    dampingRatio = Spring.DampingRatioHighBouncy,  // 0.2f - very bouncy
    stiffness = Spring.StiffnessVeryLow,           // 50f - slow
    visibilityThreshold = 0.1f
)

// Damping ratio presets
Spring.DampingRatioHighBouncy     // 0.2f
Spring.DampingRatioMediumBouncy   // 0.5f
Spring.DampingRatioLowBouncy      // 0.75f
Spring.DampingRatioNoBouncy       // 1.0f

// Stiffness presets
Spring.StiffnessHigh              // 10000f
Spring.StiffnessMedium            // 1500f
Spring.StiffnessMediumLow         // 400f
Spring.StiffnessLow               // 200f
Spring.StiffnessVeryLow           // 50f
```

### Tween (Duration-Based)

```kotlin
// Basic tween
tween<Float>(durationMillis = 300)

// With easing
tween(
    durationMillis = 300,
    delayMillis = 100,
    easing = FastOutSlowInEasing
)

// Built-in easing curves
LinearEasing
FastOutSlowInEasing      // Decelerate
FastOutLinearInEasing    // Accelerate into exit
LinearOutSlowInEasing    // Enter deceleration
EaseInOut                // S-curve
EaseIn                   // Accelerate
EaseOut                  // Decelerate

// Custom cubic bezier
CubicBezierEasing(0.4f, 0.0f, 0.2f, 1.0f)
```

### Keyframes (Multiple Waypoints)

```kotlin
keyframes {
    durationMillis = 1000
    0f at 0 using LinearEasing           // Start
    1.5f at 300 using FastOutSlowInEasing // Overshoot at 300ms
    1.2f at 600                           // Settle back
    1.0f at 1000                          // Final value
}
```

### Repeatable and Snap

```kotlin
// Repeat N times
repeatable(
    iterations = 3,
    animation = tween(300),
    repeatMode = RepeatMode.Reverse
)

// Infinite repeat
infiniteRepeatable(
    animation = tween(1000),
    repeatMode = RepeatMode.Restart
)

// Instant (no animation)
snap(delayMillis = 0)
```

## Animatable (Low-Level Control)

```kotlin
@Composable
fun AnimatableDemo() {
    val offsetX = remember { Animatable(0f) }
    val scope = rememberCoroutineScope()

    Box(
        modifier = Modifier
            .offset { IntOffset(offsetX.value.roundToInt(), 0) }
            .size(100.dp)
            .background(Color.Blue, CircleShape)
            .pointerInput(Unit) {
                detectTapGestures { tapOffset ->
                    scope.launch {
                        // Animate to tap position
                        offsetX.animateTo(
                            targetValue = tapOffset.x,
                            animationSpec = spring(
                                dampingRatio = Spring.DampingRatioMediumBouncy
                            )
                        )
                    }
                }
            }
    )
}

// Decay animation (fling)
@Composable
fun FlingDemo() {
    val offset = remember { Animatable(0f) }
    val scope = rememberCoroutineScope()

    Box(
        modifier = Modifier
            .offset { IntOffset(offset.value.roundToInt(), 0) }
            .draggable(
                state = rememberDraggableState { delta ->
                    scope.launch {
                        offset.snapTo(offset.value + delta)
                    }
                },
                orientation = Orientation.Horizontal,
                onDragStopped = { velocity ->
                    scope.launch {
                        offset.animateDecay(
                            initialVelocity = velocity,
                            animationSpec = exponentialDecay()
                        )
                    }
                }
            )
    )
}
```

### Animatable Key Methods

```kotlin
// Animate to target
animatable.animateTo(
    targetValue = 100f,
    animationSpec = spring(),
    initialVelocity = 0f,
    block = { /* called each frame */ }
)

// Physics decay
animatable.animateDecay(
    initialVelocity = velocity,
    animationSpec = exponentialDecay()
)

// Instant change
animatable.snapTo(targetValue)

// Stop animation
animatable.stop()

// Check state
animatable.value           // Current value
animatable.velocity        // Current velocity
animatable.isRunning       // Animation active
animatable.targetValue     // Target value
```

## GraphicsLayer Animations (Performance)

```kotlin
@Composable
fun PerformantAnimation() {
    var rotated by remember { mutableStateOf(false) }
    val rotation by animateFloatAsState(
        targetValue = if (rotated) 360f else 0f,
        label = "rotation"
    )

    Box(
        modifier = Modifier
            .size(100.dp)
            .graphicsLayer {
                // GPU-accelerated transformations
                rotationZ = rotation
                scaleX = 1f + (rotation / 360f) * 0.5f
                scaleY = 1f + (rotation / 360f) * 0.5f
                alpha = 1f - (rotation / 360f) * 0.5f
                transformOrigin = TransformOrigin(0.5f, 0.5f)

                // 3D transforms
                rotationX = rotation / 2
                rotationY = rotation / 3
                cameraDistance = 12f * density
            }
            .background(Color.Blue)
            .clickable { rotated = !rotated }
    )
}
```

### GraphicsLayer Properties

```kotlin
graphicsLayer {
    // 2D transforms
    translationX = 0f
    translationY = 0f
    scaleX = 1f
    scaleY = 1f
    rotationZ = 0f

    // 3D transforms
    rotationX = 0f
    rotationY = 0f
    cameraDistance = 8f * density

    // Visual effects
    alpha = 1f
    shadowElevation = 0f
    ambientShadowColor = Color.Black
    spotShadowColor = Color.Black

    // Transform origin
    transformOrigin = TransformOrigin(0.5f, 0.5f)

    // Clipping
    clip = false
    shape = RectangleShape

    // Render effects (API 31+)
    renderEffect = BlurEffect(radiusX, radiusY)
}
```

**Why graphicsLayer?**

- GPU-accelerated (no recomposition)
- Runs on RenderThread, not UI thread
- Better performance than Modifier.rotate/scale
- Supports 3D transformations

## Shared Element Transitions

### Basic Shared Elements (Compose 1.7+)

```kotlin
@Composable
fun SharedElementDemo() {
    var showDetail by remember { mutableStateOf(false) }

    SharedTransitionLayout {
        AnimatedContent(
            targetState = showDetail,
            label = "shared_transition"
        ) { isDetail ->
            if (!isDetail) {
                // List view
                Card(
                    modifier = Modifier
                        .sharedElement(
                            state = rememberSharedContentState(key = "card"),
                            animatedVisibilityScope = this@AnimatedContent
                        )
                        .clickable { showDetail = true }
                        .padding(16.dp)
                ) {
                    Row {
                        Image(
                            painter = painterResource(R.drawable.image),
                            contentDescription = null,
                            modifier = Modifier
                                .sharedElement(
                                    state = rememberSharedContentState(key = "image"),
                                    animatedVisibilityScope = this@AnimatedContent
                                )
                                .size(80.dp)
                        )
                        Text(
                            text = "Title",
                            modifier = Modifier.sharedBounds(
                                sharedContentState = rememberSharedContentState(key = "title"),
                                animatedVisibilityScope = this@AnimatedContent
                            )
                        )
                    }
                }
            } else {
                // Detail view
                Column(
                    modifier = Modifier
                        .sharedElement(
                            state = rememberSharedContentState(key = "card"),
                            animatedVisibilityScope = this@AnimatedContent
                        )
                        .fillMaxSize()
                        .clickable { showDetail = false }
                ) {
                    Image(
                        painter = painterResource(R.drawable.image),
                        contentDescription = null,
                        modifier = Modifier
                            .sharedElement(
                                state = rememberSharedContentState(key = "image"),
                                animatedVisibilityScope = this@AnimatedContent
                            )
                            .fillMaxWidth()
                            .height(300.dp)
                    )
                    Text(
                        text = "Title",
                        style = MaterialTheme.typography.headlineLarge,
                        modifier = Modifier.sharedBounds(
                            sharedContentState = rememberSharedContentState(key = "title"),
                            animatedVisibilityScope = this@AnimatedContent
                        )
                    )
                }
            }
        }
    }
}
```

### Shared Elements with Navigation

```kotlin
@Composable
fun SharedElementNavigation() {
    val navController = rememberNavController()

    SharedTransitionLayout {
        NavHost(navController = navController, startDestination = "list") {
            composable("list") {
                ListScreen(
                    onItemClick = { itemId ->
                        navController.navigate("detail/$itemId")
                    },
                    animatedVisibilityScope = this
                )
            }
            composable("detail/{id}") { backStackEntry ->
                val id = backStackEntry.arguments?.getString("id") ?: ""
                DetailScreen(
                    itemId = id,
                    onBack = { navController.popBackStack() },
                    animatedVisibilityScope = this
                )
            }
        }
    }
}

@Composable
fun SharedTransitionScope.ListItem(
    item: Item,
    onClick: () -> Unit,
    animatedVisibilityScope: AnimatedVisibilityScope
) {
    Card(
        modifier = Modifier
            .sharedBounds(
                sharedContentState = rememberSharedContentState(key = "container-${item.id}"),
                animatedVisibilityScope = animatedVisibilityScope,
                resizeMode = SharedTransitionScope.ResizeMode.RemeasureToBounds
            )
            .clickable(onClick = onClick)
    ) {
        AsyncImage(
            model = item.imageUrl,
            contentDescription = null,
            modifier = Modifier.sharedElement(
                state = rememberSharedContentState(key = "image-${item.id}"),
                animatedVisibilityScope = animatedVisibilityScope
            )
        )
    }
}
```

## Performance Best Practices

### Avoid Recomposition During Animation

```kotlin
// ❌ BAD: Recomposes entire Column every frame
@Composable
fun BadAnimation() {
    var progress by remember { mutableFloatStateOf(0f) }

    Column {
        Text("Header")
        Box(Modifier.offset(x = (progress * 100).dp))
        Text("Footer")
    }
}

// ✅ GOOD: Isolate animated composable
@Composable
fun GoodAnimation() {
    var progress by remember { mutableFloatStateOf(0f) }

    Column {
        Text("Header")
        AnimatedBox(progress)
        Text("Footer")
    }
}

@Composable
private fun AnimatedBox(progress: Float) {
    Box(Modifier.offset(x = (progress * 100).dp))
}

// ✅ BETTER: Use graphicsLayer (no recomposition)
@Composable
fun BestAnimation() {
    var progress by remember { mutableFloatStateOf(0f) }

    Column {
        Text("Header")
        Box(
            Modifier.graphicsLayer {
                translationX = progress * 100f
            }
        )
        Text("Footer")
    }
}
```

### Use derivedStateOf for Computed Values

```kotlin
@Composable
fun ScrollBasedAnimation() {
    val scrollState = rememberScrollState()

    // ✅ Only recalculates when scroll changes significantly
    val headerAlpha by remember {
        derivedStateOf {
            (1f - (scrollState.value / 500f)).coerceIn(0f, 1f)
        }
    }

    val headerScale by remember {
        derivedStateOf {
            (1f - (scrollState.value / 1000f)).coerceIn(0.8f, 1f)
        }
    }

    Column(Modifier.verticalScroll(scrollState)) {
        Box(
            Modifier
                .fillMaxWidth()
                .height(200.dp)
                .graphicsLayer {
                    alpha = headerAlpha
                    scaleX = headerScale
                    scaleY = headerScale
                }
                .background(Color.Blue)
        )
        // Content...
    }
}
```

### Remember Animation Specs

```kotlin
@Composable
fun OptimizedAnimations() {
    var expanded by remember { mutableStateOf(false) }

    // ✅ Animation specs created once
    val expandSpec = remember {
        spring<Dp>(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        )
    }

    val fadeSpec = remember {
        tween<Float>(durationMillis = 300)
    }

    val height by animateDpAsState(
        targetValue = if (expanded) 200.dp else 80.dp,
        animationSpec = expandSpec,
        label = "height"
    )

    val alpha by animateFloatAsState(
        targetValue = if (expanded) 1f else 0.6f,
        animationSpec = fadeSpec,
        label = "alpha"
    )
}
```

### Lazy List Animation Keys

```kotlin
@Composable
fun AnimatedLazyList(items: List<Item>) {
    LazyColumn {
        items(
            items = items,
            key = { it.id }  // CRITICAL for animations
        ) { item ->
            ItemCard(
                item = item,
                modifier = Modifier.animateItem(
                    fadeInSpec = tween(300),
                    fadeOutSpec = tween(300),
                    placementSpec = spring()
                )
            )
        }
    }
}
```

## Integration with Lottie

```kotlin
dependencies {
    implementation("com.airbnb.android:lottie-compose")
}

@Composable
fun LottieAnimationDemo() {
    val composition by rememberLottieComposition(
        LottieCompositionSpec.RawRes(R.raw.animation)
    )

    // Controlled animation
    var isPlaying by remember { mutableStateOf(true) }
    val progress by animateLottieCompositionAsState(
        composition = composition,
        isPlaying = isPlaying,
        iterations = LottieConstants.IterateForever,
        speed = 1f
    )

    LottieAnimation(
        composition = composition,
        progress = { progress },
        modifier = Modifier
            .size(200.dp)
            .clickable { isPlaying = !isPlaying }
    )
}

// Manual progress control
@Composable
fun LottieWithManualProgress() {
    val composition by rememberLottieComposition(
        LottieCompositionSpec.RawRes(R.raw.animation)
    )
    var sliderProgress by remember { mutableFloatStateOf(0f) }

    Column {
        LottieAnimation(
            composition = composition,
            progress = { sliderProgress },
            modifier = Modifier.size(200.dp)
        )

        Slider(
            value = sliderProgress,
            onValueChange = { sliderProgress = it },
            valueRange = 0f..1f
        )
    }
}
```

## Animation Debugging

### Compose Animation Preview

```kotlin
@Preview
@Composable
fun AnimationPreview() {
    // Use @Preview with animations
    var state by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        while (true) {
            delay(1000)
            state = !state
        }
    }

    AnimatedBox(isExpanded = state)
}
```

### Slow Motion for Debugging

```kotlin
// In debug builds, slow down animations
val debugAnimationSpec = remember {
    if (BuildConfig.DEBUG) {
        tween<Float>(durationMillis = 3000)  // 10x slower
    } else {
        tween<Float>(durationMillis = 300)
    }
}
```

## Summary: Animation Selection Guide

| Scenario                        | Recommended API               |
|---------------------------------|-------------------------------|
| Single property change          | `animate*AsState`             |
| Multiple coordinated properties | `updateTransition`            |
| Enter/exit visibility           | `AnimatedVisibility`          |
| Content switching               | `AnimatedContent`             |
| Infinite/looping                | `rememberInfiniteTransition`  |
| Gesture-driven                  | `Animatable` + `pointerInput` |
| Performance-critical            | `graphicsLayer`               |
| Shared elements                 | `SharedTransitionLayout`      |
| Complex sequences               | `Animatable` with coroutines  |
| External animations             | Lottie                        |
