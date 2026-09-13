import 'dart:async';

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
/// Holds one [PackageGraph] for a feature package in the current isolate.
///
/// {@macro package_context.not_di}
///
/// [initialize] assigns the graph once. [refresh] replaces it. Reading before
/// initialization throws [PackageContextNotInitialized].
///
/// Keep one top-level instance per package. Do not export it from the package
/// barrel. Expose typed getters and an `initPackage` entry point instead.
/// Initialize the context separately in each isolate.
/// {@endtemplate}
final class PackageContext<C extends PackageConfig, D extends PackageDependencies> {
  PackageGraph<C, D>? _graph;
  Future<void>? _pendingInitialization;
  final _bindingZoneKey = Object();

  /// Whether a complete [PackageGraph] has been assigned.
  ///
  /// This does not indicate whether package binding has completed successfully.
  /// Await [ensureInitialized] to wait for binding.
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
  ///
  /// Throws [PackageContextInitializationInProgress] while binding is pending.
  void refresh(
    PackageGraph<C, D> graph,
  ) {
    if (_pendingInitialization != null) {
      throw PackageContextInitializationInProgress();
    }
    _graph = graph;
  }

  /// Clears the graph so [initialize] can run again.
  ///
  /// Test-only. Production in-process relaunch uses [refresh].
  /// Throws [PackageContextInitializationInProgress] while binding is pending.
  @visibleForTesting
  void reset() {
    if (_pendingInitialization != null) {
      throw PackageContextInitializationInProgress();
    }
    _graph = null;
  }

  /// Initializes or refreshes the graph, then binds package-owned types.
  ///
  /// [isBound] means the host's package registration is fully ready. [bind]
  /// registers package-owned types synchronously or asynchronously. This library
  /// does not know the container.
  ///
  /// - Initialized and bound → no-op.
  /// - Initialized and unbound → [refresh], then [bind].
  /// - Empty and unbound → set the graph, then [bind].
  /// - Empty and bound → set the graph without [bind].
  ///
  /// The graph is available before [bind] runs. While binding is pending, calls
  /// with identical config and dependencies objects share the same future,
  /// regardless of the graph wrapper or [isBound]. Only the first [bind] runs.
  /// A different graph or reentry from this operation's [bind] returns a future
  /// that fails with [PackageContextInitializationInProgress].
  ///
  /// A binding failure retains the assigned graph and forwards the original
  /// error and stack trace. No automatic retry or container rollback occurs.
  /// The host must clean up partial registration before retrying with
  /// `isBound: false`. [isInitialized] only reports graph availability.
  Future<void> ensureInitialized({
    required PackageGraph<C, D> graph,
    required bool isBound,
    required FutureOr<void> Function() bind,
  }) {
    final pending = _pendingInitialization;
    if (pending != null) {
      if (identical(Zone.current[_bindingZoneKey], pending) ||
          !identical(_graph!.config, graph.config) ||
          !identical(_graph!.dependencies, graph.dependencies)) {
        return Future<void>.error(PackageContextInitializationInProgress());
      }
      return pending;
    }

    if (isInitialized && isBound) {
      return Future<void>.value();
    }

    refresh(graph);
    if (isBound) {
      return Future<void>.value();
    }

    final completion = Completer<void>();
    _pendingInitialization = completion.future;
    runZoned(
      () => Future<void>.sync(bind),
      zoneValues: {_bindingZoneKey: completion.future},
    ).then<void>(
      (_) {
        _pendingInitialization = null;
        completion.complete();
      },
      onError: (Object error, StackTrace stackTrace) {
        _pendingInitialization = null;
        completion.completeError(error, stackTrace);
      },
    );
    return completion.future;
  }

  PackageGraph<C, D> _requireGraph() {
    final graph = _graph;
    if (graph != null) {
      return graph;
    }
    throw PackageContextNotInitialized();
  }
}
