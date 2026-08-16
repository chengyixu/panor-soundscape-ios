# App Sector

Composes live dependencies, the single custom five-surface navigation renderer, full-screen player presentation, and app lifecycle only. Native `TabView` chrome must never coexist with `SoundscapeTabBar`, and the entire app shell leaves the hierarchy while the player is active. No request construction, persistence, media internals, or feature business state belongs here.
