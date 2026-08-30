import 'package_role.dart';

/// Declares a package's name, role, and allowed dependency targets.
final class PackageContext {
  /// Creates a package context.
  const PackageContext({
    required this.name,
    required this.role,
    this.allowedDependencies = const {},
  });

  /// Package name as it appears in `pubspec.yaml`.
  final String name;

  /// Architectural role of this package.
  final PackageRole role;

  /// Roles this package may depend on.
  final Set<PackageRole> allowedDependencies;

  /// Whether this package may depend on [other].
  ///
  /// A package may always depend on itself. Otherwise [other]'s role must be
  /// listed in [allowedDependencies].
  bool canDependOn(PackageContext other) {
    if (name == other.name) {
      return true;
    }

    return allowedDependencies.contains(other.role);
  }

  @override
  bool operator ==(Object other) {
    return other is PackageContext &&
        other.name == name &&
        other.role == role &&
        _sameRoles(other.allowedDependencies);
  }

  @override
  int get hashCode =>
      Object.hash(name, role, Object.hashAllUnordered(allowedDependencies));

  bool _sameRoles(Set<PackageRole> other) {
    return allowedDependencies.length == other.length &&
        allowedDependencies.containsAll(other);
  }
}
