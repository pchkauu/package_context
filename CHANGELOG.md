# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 1.0.0 - 2026-08-30

### Added

- `PackageConfig` and `PackageDependencies` as the host-facing boundary types.
- `PackageContext` with one-time setters and typed getters for `config` and `dependencies`.
- `isInitialized`, `true` only when both values are set.
- `refresh` to replace an initialized graph in the same process.
- `reset` to clear the graph in tests.
