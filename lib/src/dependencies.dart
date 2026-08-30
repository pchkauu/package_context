import 'package:equatable/equatable.dart';

/// {@template package_context.PackageDependencies}
/// Host objects a feature package must not create: HTTP clients, sessions,
/// adapters, host implementations of package interfaces.
///
/// Objects the package constructs itself belong in the package DI, not here.
///
/// Subclasses must implement [props].
/// {@endtemplate}
abstract base class PackageDependencies extends Equatable {
  /// {@macro package_context.PackageDependencies}
  const PackageDependencies();
}
