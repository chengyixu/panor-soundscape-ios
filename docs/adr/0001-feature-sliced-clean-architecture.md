# ADR 0001: Feature-Sliced SwiftUI with Contract-Centered Boundaries

**Status:** Accepted

## Decision

Use feature slices for UI and presentation, with a shared contract kernel and infrastructure adapters. Feature models depend on repository/media/auth protocols. The app target composes concrete implementations.

## Why

Soundscape has several independent interaction cycles—browse, map, rank, record, publish, authenticate, manage, play—that should not share one mutable application model. A contract-centered kernel makes backend changes compiler-visible while keeping UIKit/SwiftUI, AVFoundation, MapKit, Keychain, and URLSession out of domain state.

## Consequences

- New backend fields are added to one DTO mapping.
- Features can use hermetic repositories in tests and previews.
- Native framework integration remains replaceable without copying domain rules.
- The generated Xcode project is not hand-edited; `project.yml` is canonical.
