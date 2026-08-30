import 'package:package_context/src/config.dart';
import 'package:package_context/src/dependencies.dart';

/// {@template package_context.PackageGraph}
/// A complete host graph: [config] and [dependencies] together.
///
/// The pair is the only valid initialized state. Partial graphs cannot exist.
/// {@endtemplate}
final class PackageGraph<C extends PackageConfig, D extends PackageDependencies> {
  /// Host values for the feature package.
  final C config;

  /// Host objects the feature package must not create.
  final D dependencies;

  /// {@macro package_context.PackageGraph}
  const PackageGraph({
    required this.config,
    required this.dependencies,
  });
}
