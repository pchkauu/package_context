# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 2.2.0 - 2026-09-14

### Changed

- Adopted the stricter analysis and formatter configuration from `domain_error`.
- Updated the example and tests to satisfy the newly enabled rules.

## 2.1.0 - 2026-09-13

### Added

- Shared initialization results for concurrent calls with identical config and dependencies objects.
- `PackageContextInitializationInProgress` for conflicting graphs, reentrant binding, and graph changes during binding.
- Regression tests for initialization, failure recovery, isolate boundaries, and the test bootstrap example.
- CI checks on Dart 3.13.2 and stable.

### Changed

- `bind` accepts synchronous and asynchronous callbacks through `FutureOr<void>`.
- Binding failures retain the graph, preserve the original error and stack trace, and allow explicit retry after host cleanup.
- Lifecycle documentation specifies all four initialized/bound combinations and isolate-local ownership.
- README diagrams use a consistent layout and explain graph ownership, wiring, and binding readiness.
- `make check` checks formatting without rewriting source files and runs the main example.

## 2.0.1 - 2026-08-30

### Added

- Architecture, wiring, and lifecycle diagrams in the README.

## 2.0.0 - 2026-08-30

### Added

- `PackageGraph` as the only valid initialized state.
- `initialize` to assign the graph once.
- `ensureInitialized` for the no-op / refresh / initialize bootstrap.
- `PackageContextNotInitialized` and `PackageContextAlreadyInitialized`.

### Removed

- One-time setters for `config` and `dependencies`.
- `Equatable` on `PackageConfig` and `PackageDependencies`.

### Changed

- `refresh` now takes a `PackageGraph`.
- Reading an empty context throws `PackageContextNotInitialized`.

## 1.0.0 - 2026-08-30

### Added

- `PackageConfig` and `PackageDependencies` as the host-facing boundary types.
- `PackageContext` with one-time setters and typed getters for `config` and `dependencies`.
- `isInitialized`, `true` only when both values are set.
- `refresh` to replace an initialized graph in the same process.
- `reset` to clear the graph in tests.
