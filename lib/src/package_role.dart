/// Architectural role of a Dart package in an application.
enum PackageRole {
  /// The runnable application that composes feature packages.
  application,

  /// Business rules and the domain model.
  domain,

  /// Persistence, networking, and other infrastructure.
  data,

  /// UI and presentation.
  presentation,
}
