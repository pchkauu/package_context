import 'package:package_context/package_context.dart';
import 'package:test/test.dart';

void main() {
  late PackageContext<_TestConfig, _TestDependencies> context;

  setUp(() {
    context = PackageContext<_TestConfig, _TestDependencies>();
  });

  group('isInitialized', () {
    test('is false before config and dependencies are set', () {
      expect(context.isInitialized, isFalse);
    });

    test('is false when only config is set', () {
      context.config = const _TestConfig(apiUrl: 'https://example.com');

      expect(context.isInitialized, isFalse);
    });

    test('is false when only dependencies are set', () {
      context.dependencies = const _TestDependencies(client: 'http');

      expect(context.isInitialized, isFalse);
    });

    test('is true after config and dependencies are set', () {
      context
        ..config = const _TestConfig(apiUrl: 'https://example.com')
        ..dependencies = const _TestDependencies(client: 'http');

      expect(context.isInitialized, isTrue);
    });
  });

  group('config', () {
    test('throws when it has not been initialized', () {
      expect(() => context.config, throwsStateError);
    });

    test('returns the assigned value', () {
      const config = _TestConfig(apiUrl: 'https://example.com');

      context.config = config;

      expect(context.config, same(config));
    });

    test('throws when assigned more than once', () {
      context.config = const _TestConfig(apiUrl: 'https://example.com');

      expect(() => context.config = const _TestConfig(apiUrl: 'https://other.example'), throwsStateError);
    });
  });

  group('dependencies', () {
    test('throws when they have not been initialized', () {
      expect(() => context.dependencies, throwsStateError);
    });

    test('returns the assigned value', () {
      const dependencies = _TestDependencies(client: 'http');

      context.dependencies = dependencies;

      expect(context.dependencies, same(dependencies));
    });

    test('throws when assigned more than once', () {
      context.dependencies = const _TestDependencies(client: 'http');

      expect(() => context.dependencies = const _TestDependencies(client: 'dio'), throwsStateError);
    });
  });

  group('refresh', () {
    test('replaces an initialized graph', () {
      context
        ..config = const _TestConfig(apiUrl: 'https://example.com')
        ..dependencies = const _TestDependencies(client: 'http');

      const nextConfig = _TestConfig(apiUrl: 'https://other.example');
      const nextDependencies = _TestDependencies(client: 'dio');

      context.refresh(config: nextConfig, dependencies: nextDependencies);

      expect(context.isInitialized, isTrue);
      expect(context.config, same(nextConfig));
      expect(context.dependencies, same(nextDependencies));
    });

    test('initializes an empty context', () {
      const config = _TestConfig(apiUrl: 'https://example.com');
      const dependencies = _TestDependencies(client: 'http');

      context.refresh(config: config, dependencies: dependencies);

      expect(context.isInitialized, isTrue);
      expect(context.config, same(config));
      expect(context.dependencies, same(dependencies));
    });
  });

  group('reset', () {
    test('clears initialized values', () {
      context
        ..config = const _TestConfig(apiUrl: 'https://example.com')
        ..dependencies = const _TestDependencies(client: 'http');

      context.reset();

      expect(context.isInitialized, isFalse);
      expect(() => context.config, throwsStateError);
      expect(() => context.dependencies, throwsStateError);
    });

    test('allows initialization after reset', () {
      context
        ..config = const _TestConfig(apiUrl: 'https://example.com')
        ..dependencies = const _TestDependencies(client: 'http')
        ..reset()
        ..config = const _TestConfig(apiUrl: 'https://other.example')
        ..dependencies = const _TestDependencies(client: 'dio');

      expect(context.config.apiUrl, 'https://other.example');
      expect(context.dependencies.client, 'dio');
    });
  });
}

final class _TestConfig extends PackageConfig {
  final String apiUrl;

  const _TestConfig({required this.apiUrl});

  @override
  List<Object?> get props => [apiUrl];
}

final class _TestDependencies extends PackageDependencies {
  final String client;

  const _TestDependencies({required this.client});

  @override
  List<Object?> get props => [client];
}
