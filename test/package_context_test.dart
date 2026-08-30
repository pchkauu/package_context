import 'package:package_context/package_context.dart';
import 'package:test/test.dart';

void main() {
  const domain = PackageContext(name: 'domain', role: PackageRole.domain);
  const data = PackageContext(
    name: 'data',
    role: PackageRole.data,
    allowedDependencies: {PackageRole.domain},
  );
  const app = PackageContext(
    name: 'app',
    role: PackageRole.application,
    allowedDependencies: {
      PackageRole.domain,
      PackageRole.data,
      PackageRole.presentation,
    },
  );

  group('PackageContext.canDependOn', () {
    test('allows a package to depend on itself', () {
      expect(domain.canDependOn(domain), isTrue);
    });

    test('allows a declared dependency', () {
      expect(data.canDependOn(domain), isTrue);
      expect(app.canDependOn(data), isTrue);
    });

    test('rejects a dependency that is not declared', () {
      expect(domain.canDependOn(data), isFalse);
      expect(data.canDependOn(app), isFalse);
    });
  });

  group('PackageContext equality', () {
    test('treats contexts with the same values as equal', () {
      const otherData = PackageContext(
        name: 'data',
        role: PackageRole.data,
        allowedDependencies: {PackageRole.domain},
      );

      expect(data, equals(otherData));
      expect(data.hashCode, otherData.hashCode);
    });

    test('treats contexts with different values as not equal', () {
      expect(data, isNot(equals(domain)));
      expect(data, isNot(equals(app)));
    });
  });
}
