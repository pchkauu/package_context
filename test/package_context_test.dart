import 'package:package_context/package_context.dart';
import 'package:test/test.dart';

void main() {
  late PackageContext<_TestConfig, _TestDependencies> context;

  setUp(() {
    context = PackageContext<_TestConfig, _TestDependencies>();
  });

  PackageGraph<_TestConfig, _TestDependencies> graph({
    String apiUrl = 'https://example.com',
    String client = 'http',
  }) {
    return PackageGraph(
      config: _TestConfig(
        apiUrl: apiUrl,
      ),
      dependencies: _TestDependencies(
        client: client,
      ),
    );
  }

  group('isInitialized', () {
    test('is false before the graph is set', () {
      expect(context.isInitialized, isFalse);
    });

    test('is true after initialize', () {
      context.initialize(
        graph(),
      );

      expect(context.isInitialized, isTrue);
    });
  });

  group('config and dependencies', () {
    test('throw when the graph has not been initialized', () {
      expect(
        () => context.config,
        throwsA(isA<PackageContextNotInitialized>()),
      );
      expect(
        () => context.dependencies,
        throwsA(isA<PackageContextNotInitialized>()),
      );
    });

    test('return the assigned graph', () {
      final next = graph();

      context.initialize(
        next,
      );

      expect(context.config, same(next.config));
      expect(context.dependencies, same(next.dependencies));
    });
  });

  group('initialize', () {
    test('throws when the graph is already assigned', () {
      context.initialize(
        graph(),
      );

      expect(
        () => context.initialize(
          graph(
            apiUrl: 'https://other.example',
          ),
        ),
        throwsA(isA<PackageContextAlreadyInitialized>()),
      );
    });
  });

  group('refresh', () {
    test('replaces an initialized graph', () {
      context.initialize(
        graph(),
      );

      final next = graph(
        apiUrl: 'https://other.example',
        client: 'dio',
      );

      context.refresh(
        next,
      );

      expect(context.isInitialized, isTrue);
      expect(context.config, same(next.config));
      expect(context.dependencies, same(next.dependencies));
    });

    test('initializes an empty context', () {
      final next = graph();

      context.refresh(
        next,
      );

      expect(context.isInitialized, isTrue);
      expect(context.config, same(next.config));
      expect(context.dependencies, same(next.dependencies));
    });
  });

  group('reset', () {
    test('clears the graph', () {
      context.initialize(
        graph(),
      );

      context.reset();

      expect(context.isInitialized, isFalse);
      expect(
        () => context.config,
        throwsA(isA<PackageContextNotInitialized>()),
      );
      expect(
        () => context.dependencies,
        throwsA(isA<PackageContextNotInitialized>()),
      );
    });

    test('allows initialize after reset', () {
      context.initialize(
        graph(),
      );
      context.reset();

      final next = graph(
        apiUrl: 'https://other.example',
        client: 'dio',
      );
      context.initialize(
        next,
      );

      expect(context.config.apiUrl, 'https://other.example');
      expect(context.dependencies.client, 'dio');
    });
  });

  group('ensureInitialized', () {
    test('is a no-op when initialized and bound', () async {
      final first = graph();
      context.initialize(
        first,
      );

      var bound = false;
      await context.ensureInitialized(
        graph: graph(
          apiUrl: 'https://other.example',
        ),
        isBound: true,
        bind: () async {
          bound = true;
        },
      );

      expect(bound, isFalse);
      expect(context.config, same(first.config));
    });

    test('refreshes and binds when initialized and unbound', () async {
      context.initialize(
        graph(),
      );

      var bound = false;
      final next = graph(
        apiUrl: 'https://other.example',
        client: 'dio',
      );

      await context.ensureInitialized(
        graph: next,
        isBound: false,
        bind: () async {
          bound = true;
        },
      );

      expect(bound, isTrue);
      expect(context.config, same(next.config));
      expect(context.dependencies, same(next.dependencies));
    });

    test('initializes and binds when empty', () async {
      var bound = false;
      final next = graph();

      await context.ensureInitialized(
        graph: next,
        isBound: false,
        bind: () async {
          bound = true;
        },
      );

      expect(bound, isTrue);
      expect(context.config, same(next.config));
    });
  });
}

final class _TestConfig extends PackageConfig {
  final String apiUrl;

  const _TestConfig({
    required this.apiUrl,
  });
}

final class _TestDependencies extends PackageDependencies {
  final String client;

  const _TestDependencies({
    required this.client,
  });
}
