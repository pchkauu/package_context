/// {@template package_context.PackageDependencies}
/// Host objects a feature package must not create: HTTP clients, sessions,
/// adapters, host implementations of package interfaces.
///
/// Objects the package constructs itself belong in the package DI, not here.
/// {@endtemplate}
abstract base class PackageDependencies {
  /// {@macro package_context.PackageDependencies}
  const PackageDependencies();
}
