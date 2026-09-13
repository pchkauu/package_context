/// {@template package_context.library}
/// Isolate-local holder for one `PackageGraph` of a feature package.
///
/// The application initializes the package at startup. The package then reads
/// typed config and dependencies. The application never imports this library.
///
/// {@macro package_context.not_di}
///
/// Keep one `PackageContext` per feature package in each isolate. A new isolate
/// has its own context and must initialize it separately.
/// Graph availability does not imply that package binding is ready.
///
/// A runnable sample is in `example/package_context_example.dart`.
/// {@endtemplate}
library;

export 'src/config.dart';
export 'src/context.dart';
export 'src/dependencies.dart';
export 'src/errors.dart';
export 'src/graph.dart';
