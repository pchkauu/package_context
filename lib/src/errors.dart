/// Thrown when `PackageContext` is read before `initialize` or `refresh`.
final class PackageContextNotInitialized extends StateError {
  /// Creates a not-initialized error.
  PackageContextNotInitialized() : super('PackageContext is not initialized.');
}

/// Thrown when `PackageContext.initialize` runs on an already initialized
/// context.
final class PackageContextAlreadyInitialized extends StateError {
  /// Creates an already-initialized error.
  PackageContextAlreadyInitialized() : super('PackageContext is already initialized.');
}
