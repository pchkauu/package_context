import 'package:meta/meta.dart';
import 'package:package_context/src/config.dart';
import 'package:package_context/src/dependencies.dart';
import 'package:package_context/src/errors.dart';
import 'package:package_context/src/graph.dart';

/// {@template package_context.not_di}
/// This is not a DI container. Put host values in [PackageConfig] and host
/// objects in [PackageDependencies]. Keep repositories, use cases, and blocs
/// in the package's own container.
/// {@endtemplate}
///
/// {@template package_context.PackageContext}
/// Holds one [PackageGraph] for a feature package.
///
/// {@macro package_context.not_di}
///
/// [initialize] assigns the graph once. [refresh] replaces it. Reading before
/// initialization throws [PackageContextNotInitialized].
///
/// Keep one top-level instance per package. Do not export it from the package
/// barrel. Expose typed getters and an `initPackage` entry point instead.
/// {@endtemplate}
final class PackageContext<C extends PackageConfig, D extends PackageDependencies> {
  PackageGraph<C, D>? _graph;

  /// Whether a complete [PackageGraph] has been assigned.
  bool get isInitialized {
    return _graph != null;
  }

  /// Initialized package config.
  ///
  /// Throws [PackageContextNotInitialized] if the graph has not been assigned.
  C get config {
    return _requireGraph().config;
  }

  /// Initialized package dependencies.
  ///
  /// Throws [PackageContextNotInitialized] if the graph has not been assigned.
  D get dependencies {
    return _requireGraph().dependencies;
  }

  /// {@macro package_context.PackageContext}
  PackageContext();

  /// Assigns [graph] once.
  ///
  /// Throws [PackageContextAlreadyInitialized] if the context already holds a
  /// graph. Use [refresh] to replace it in the same process.
  void initialize(
    PackageGraph<C, D> graph,
  ) {
    if (isInitialized) {
      throw PackageContextAlreadyInitialized();
    }
    _graph = graph;
  }

  /// Replaces the graph in place.
  ///
  /// Use this when the process stays alive but the host rebuilds the graph:
  /// otherwise later reads would see the previous launch.
  void refresh(
    PackageGraph<C, D> graph,
  ) {
    _graph = graph;
  }

  /// Clears the graph so [initialize] can run again.
  ///
  /// Test-only. Production in-process relaunch uses [refresh].
  @visibleForTesting
  void reset() {
    _graph = null;
  }

  /// Initializes or refreshes the graph, then binds package-owned types.
  ///
  /// [isBound] is the host's check that its own container still holds the
  /// package graph. [bind] registers package-owned types. This library does
  /// not know the container.
  ///
  /// - Initialized and bound → no-op.
  /// - Initialized and unbound → [refresh], then [bind].
  /// - Empty → [initialize], then [bind].
  Future<void> ensureInitialized({
    required PackageGraph<C, D> graph,
    required bool isBound,
    required Future<void> Function() bind,
  }) async {
    if (isInitialized && isBound) {
      return;
    }

    if (isInitialized) {
      refresh(graph);
    } else {
      initialize(graph);
    }

    if (!isBound) {
      await bind();
    }
  }

  PackageGraph<C, D> _requireGraph() {
    final graph = _graph;
    if (graph != null) {
      return graph;
    }
    throw PackageContextNotInitialized();
  }
}
