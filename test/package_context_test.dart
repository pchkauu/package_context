import 'dart:async';
import 'dart:isolate';

import 'package:package_context/package_context.dart';
import 'package:test/test.dart';

final _isolateContext = PackageContext<_TestConfig, _TestDependencies>();

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
    test('shares the pending result for the same host objects', () async {
      final next = graph();
      final gate = Completer<void>();
      var calls = 0;
      final first = context.ensureInitialized(
        graph: next,
        isBound: false,
        bind: () async {
          calls++;
          await gate.future;
        },
      );
      final second = context.ensureInitialized(
        graph: PackageGraph(config: next.config, dependencies: next.dependencies),
        isBound: false,
        bind: () async {
          calls++;
        },
      );

      gate.complete();
      await Future.wait([first, second]);

      expect(calls, 1);
      expect(second, same(first));
    });

    test('rejects a different graph while binding without replacing it', () async {
      final next = graph();
      final gate = Completer<void>();
      final first = context.ensureInitialized(
        graph: next,
        isBound: false,
        bind: () async {
          await gate.future;
          expect(context.config, same(next.config));
          expect(context.dependencies, same(next.dependencies));
        },
      );

      try {
        await expectLater(
          context.ensureInitialized(
            graph: graph(apiUrl: 'https://other.example'),
            isBound: false,
            bind: () async {},
          ),
          throwsA(isA<PackageContextInitializationInProgress>()),
        );
      } finally {
        gate.complete();
        await first;
      }
    });

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

    test('assigns an empty context without binding when already bound', () async {
      final next = graph();
      await context.ensureInitialized(
        graph: next,
        isBound: true,
        bind: () => fail('Already bound'),
      );

      expect(context.isInitialized, isTrue);
      expect(context.config, same(next.config));
      expect(context.dependencies, same(next.dependencies));
    });

    test('supports synchronous binding with the graph already available', () async {
      final next = graph();
      var bound = false;
      await context.ensureInitialized(
        graph: next,
        isBound: false,
        bind: () {
          expect(context.config, same(next.config));
          expect(context.dependencies, same(next.dependencies));
          bound = true;
        },
      );

      expect(bound, isTrue);
    });

    test('waits for pending binding even when the caller reports bound', () async {
      final next = graph();
      final gate = Completer<void>();
      final first = context.ensureInitialized(
        graph: next,
        isBound: false,
        bind: () => gate.future,
      );
      final second = context.ensureInitialized(
        graph: next,
        isBound: true,
        bind: () => fail('Already binding'),
      );
      var completed = false;
      final observation = second.then((_) => completed = true);

      try {
        await Future<void>.value();
        expect(context.isInitialized, isTrue);
        expect(completed, isFalse);
        expect(second, same(first));
      } finally {
        gate.complete();
        await Future.wait([first, observation]);
      }
    });

    for (final changeConfig in [false, true]) {
      test('rejects changed ${changeConfig ? 'config' : 'dependencies'} objects', () async {
        final next = graph();
        final gate = Completer<void>();
        final pending = context.ensureInitialized(
          graph: next,
          isBound: false,
          bind: () => gate.future,
        );
        final other = graph();

        try {
          final rejected = context.ensureInitialized(
            graph: PackageGraph(
              config: changeConfig ? other.config : next.config,
              dependencies: changeConfig ? next.dependencies : other.dependencies,
            ),
            isBound: true,
            bind: () => fail('Conflicting bind must not run'),
          );
          await expectLater(rejected, throwsA(isA<PackageContextInitializationInProgress>()));
          expect(context.config, same(next.config));
          expect(context.dependencies, same(next.dependencies));
        } finally {
          gate.complete();
          await pending;
        }
      });
    }

    test('blocks mutation during binding and permits it after completion', () async {
      final next = graph();
      final gate = Completer<void>();
      final pending = context.ensureInitialized(
        graph: next,
        isBound: false,
        bind: () => gate.future,
      );

      try {
        expect(() => context.refresh(graph()), throwsA(isA<PackageContextInitializationInProgress>()));
        expect(context.reset, throwsA(isA<PackageContextInitializationInProgress>()));
        expect(() => context.initialize(graph()), throwsA(isA<PackageContextAlreadyInitialized>()));
        expect(context.config, same(next.config));
        expect(context.dependencies, same(next.dependencies));
      } finally {
        gate.complete();
        await pending;
      }

      final replacement = graph();
      context.refresh(replacement);
      expect(context.config, same(replacement.config));
      context.reset();
      expect(context.isInitialized, isFalse);
    });

    for (final afterAwait in [false, true]) {
      test('rejects reentry ${afterAwait ? 'after' : 'before'} await', () async {
        final next = graph();
        var rejected = false;
        await context
            .ensureInitialized(
              graph: next,
              isBound: false,
              bind: () async {
                if (afterAwait) {
                  await Future<void>.value();
                }
                await expectLater(
                  context.ensureInitialized(
                    graph: next,
                    isBound: true,
                    bind: () => fail('Reentrant bind must not run'),
                  ),
                  throwsA(isA<PackageContextInitializationInProgress>()),
                );
                rejected = true;
              },
            )
            .timeout(const Duration(seconds: 2));

        expect(rejected, isTrue);
        context.reset();
      });
    }

    for (final asynchronous in [false, true]) {
      test('retains graph and allows retry after ${asynchronous ? 'async' : 'sync'} failure', () async {
        context.initialize(graph());
        final next = graph();
        final error = StateError('Binding failed');
        final stackTrace = StackTrace.fromString('binding stack');
        var calls = 0;
        final pending = context.ensureInitialized(
          graph: next,
          isBound: false,
          bind: () {
            calls++;
            if (asynchronous) {
              return Future<void>.error(error, stackTrace);
            }
            Error.throwWithStackTrace(error, stackTrace);
          },
        );
        final shared = context.ensureInitialized(
          graph: next,
          isBound: false,
          bind: () => fail('Duplicate binding'),
        );
        expect(shared, same(pending));

        await pending.then<void>(
          (_) => fail('Binding must fail'),
          onError: (Object caught, StackTrace caughtStack) {
            expect(caught, same(error));
            expect(caughtStack.toString(), stackTrace.toString());
          },
        );
        expect(calls, 1);
        expect(context.isInitialized, isTrue);
        expect(context.config, same(next.config));
        expect(context.dependencies, same(next.dependencies));

        final replacement = graph();
        await context.ensureInitialized(
          graph: replacement,
          isBound: false,
          bind: () {
            calls++;
          },
        );
        expect(calls, 2);
        expect(context.config, same(replacement.config));
        context.reset();
      });
    }

    test('binding a separate context is allowed', () async {
      final other = PackageContext<_TestConfig, _TestDependencies>();
      final next = graph();
      await context.ensureInitialized(
        graph: next,
        isBound: false,
        bind: () => other.ensureInitialized(graph: next, isBound: false, bind: () {}),
      );

      expect(other.config, same(next.config));
    });

    test('old binding callbacks can initialize again after completion', () async {
      late Future<void> Function() retry;
      final next = graph();
      await context.ensureInitialized(
        graph: next,
        isBound: false,
        bind: () {
          retry = Zone.current.bindCallback(
            () => context.ensureInitialized(
              graph: next,
              isBound: false,
              bind: () {},
            ),
          );
        },
      );

      await retry();
      expect(context.config, same(next.config));
    });
  });

  test('each isolate has its own context', () async {
    _isolateContext.initialize(graph());
    addTearDown(_isolateContext.reset);

    expect(_isolateContext.isInitialized, isTrue);
    expect(await Isolate.run(() => _isolateContext.isInitialized), isFalse);
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
