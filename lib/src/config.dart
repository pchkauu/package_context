import 'package:equatable/equatable.dart';

/// {@template package_context.PackageConfig}
/// Host values for a feature package: URLs, keys, flags, timeouts.
///
/// An empty subclass is valid. The instance is still required:
/// `PackageContext.isInitialized` is `false` until both config and
/// dependencies are set.
///
/// Resolve flavors and `--dart-define` in the application. Pass ready values
/// here. Do not put clients or services in this type.
///
/// Subclasses must implement [props].
/// {@endtemplate}
abstract base class PackageConfig extends Equatable {
  /// {@macro package_context.PackageConfig}
  const PackageConfig();
}
