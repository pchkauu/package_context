import 'package:meta/meta.dart';
import 'package:package_context/src/config.dart';
import 'package:package_context/src/dependencies.dart';

/// {@template package_context.not_di}
/// This is not a DI container. Put host values in [PackageConfig] and host
/// objects in [PackageDependencies]. Keep repositories, use cases, and blocs
/// in the package's own container.
/// {@endtemplate}
///
/// {@template package_context.PackageContext}
/// Holds one [config] and one [dependencies] graph for a feature package.
///
/// {@macro package_context.not_di}
///
/// Setters assign each value once. [refresh] replaces an already-initialized
/// graph. Reading before initialization throws [StateError].
///
/// Keep one top-level instance per package. Do not export it from the package
/// barrel. Expose typed getters and an `initPackage` entry point instead.
/// {@endtemplate}
final class PackageContext<C extends PackageConfig, D extends PackageDependencies> {
  C? _config;
  D? _dependencies;

  /// Whether both [config] and [dependencies] have been assigned.
  bool get isInitialized {
    return _config != null && _dependencies != null;
  }

  /// Initialized package config.
  ///
  /// Throws [StateError] if it has not been assigned yet.
  C get config {
    const op = 'PackageContext.config():';
    final config = _config;
    if (config != null) {
      return config;
    }
    throw StateError('$op PackageConfig not initialized');
  }

  /// Assigns [config] once.
  ///
  /// Throws [StateError] if config is already initialized. Use [refresh] to
  /// replace the graph in the same process.
  set config(C config) {
    const op = 'PackageContext.config:';
    if (_config != null) {
      throw StateError('$op PackageConfig already initialized');
    }
    _config = config;
  }

  /// Initialized package dependencies.
  ///
  /// Throws [StateError] if they have not been assigned yet.
  D get dependencies {
    const op = 'PackageContext.dependencies():';
    final dependencies = _dependencies;
    if (dependencies != null) {
      return dependencies;
    }
    throw StateError('$op PackageDependencies not initialized');
  }

  /// Assigns [dependencies] once.
  ///
  /// Throws [StateError] if dependencies are already initialized. Use
  /// [refresh] to replace the graph in the same process.
  set dependencies(D dependencies) {
    const op = 'PackageContext.dependencies:';
    if (_dependencies != null) {
      throw StateError('$op PackageDependencies already initialized');
    }
    _dependencies = dependencies;
  }

  /// {@macro package_context.PackageContext}
  PackageContext();

  /// Replaces an already-initialized configuration in place.
  ///
  /// For in-process app relaunches (integration tests reset GetIt and run
  /// `main()` again in the same process): the process-wide manager would
  /// otherwise keep serving the first launch's graph, so package repositories
  /// would call the backend through the previous launch's Dio — with the
  /// previous user's token.
  ///
  /// Do not use setters after the first init. Use this method.
  void refresh({required C config, required D dependencies}) {
    _config = config;
    _dependencies = dependencies;
  }

  /// Clears [config] and [dependencies] so the context can be initialized
  /// again.
  ///
  /// Test-only. Production in-process relaunch uses [refresh].
  @visibleForTesting
  void reset() {
    _config = null;
    _dependencies = null;
  }
}
