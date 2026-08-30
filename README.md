# package_context

Holds one config and one dependency graph for a feature package.

The app initializes the package at startup. After that the package reads typed
`config` and `dependencies`. The app never imports `package_context`.

![Architecture, ownership, import direction, and the atomic graph invariant](assets/overview.png)

This is not a DI container. Put host values and host objects here. Keep
repositories, use cases, and blocs in the package's own container.

| Type | Content | Examples |
|---|---|---|
| `PackageConfig` | Values from the host | URL, keys, flags |
| `PackageDependencies` | Objects the package must not create | HTTP client, session, adapters |
| `PackageGraph` | Config and dependencies together | The only valid initialized state |

One package — one `PackageContext`. It lives as long as the process.

An empty `Config` is fine. The instance is still required.

## Install

Add the dependency to the **feature package**, not to the app:

```yaml
dependencies:
  package_context: ^2.0.0
```

In a monorepo:

```yaml
dependencies:
  package_context:
    path: ../package_context
```

## Wire a feature package

The samples use a fictional `catalog` package.

![Feature layout, placement decision tree, and package wiring guardrails](assets/boundaries.png)

### Layout

```
packages/catalog/
  lib/catalog.dart
  lib/src/config/config.dart
  lib/src/dependencies/dependencies.dart
  lib/src/core/package_context.dart
  lib/src/core/init_package.dart
  test/flutter_test_config.dart
```

Export `Config`, `Dependencies`, and `initPackage`. Do not export `packageContext`.

```dart
export 'src/config/config.dart';
export 'src/core/init_package.dart';
export 'src/dependencies/dependencies.dart';
```

### Config

Import `package_context` with an alias. The app resolves flavors and
`--dart-define`. The package receives ready values.

```dart
import 'package:package_context/package_context.dart' as package_context;

final class Config extends package_context.PackageConfig {
  final Uri baseUrl;
  final bool isEnabled;

  const Config({
    required this.baseUrl,
    required this.isEnabled,
  });
}
```

No values? Keep an empty config:

```dart
final class Config extends package_context.PackageConfig {
  const Config();
}
```

### Dependencies

Host infrastructure and host implementations of package interfaces go here.
Objects the package constructs itself do not.

```dart
import 'package:package_context/package_context.dart' as package_context;

abstract interface class ApiClient {
  Future<List<int>> get(Uri url);
}

abstract interface class Session {
  String? get userId;
}

final class Dependencies extends package_context.PackageDependencies {
  final ApiClient apiClient;
  final Session session;

  const Dependencies({
    required this.apiClient,
    required this.session,
  });
}
```

- Interface in the package, implementation in the app → `Dependencies`
- Host client, retry, clock → `Dependencies`
- Package-built repository, use case, bloc → package DI

### Context

One singleton. Typed getters. Internal code imports the getters, not
`package_context`.

```dart
import 'package:package_context/package_context.dart' as package_context;

final packageContext = package_context.PackageContext<Config, Dependencies>();

Config get config => packageContext.config;

Dependencies get dependencies => packageContext.dependencies;
```

### initPackage

Call it after the host can build every `Dependencies` field.

- Already initialized and package DI is alive → return.
- Holder is alive, package DI was reset (same process, `main()` ran again) →
  `refresh`, then register again.
- First start → `initialize`, then register.

Do not call `initialize` twice. Use `refresh` or `ensureInitialized`.

```dart
Future<void> initPackage({
  required Config config,
  required Dependencies dependencies,
}) {
  return packageContext.ensureInitialized(
    graph: package_context.PackageGraph(
      config: config,
      dependencies: dependencies,
    ),
    isBound: getIt.isRegistered<CatalogFacade>(),
    bind: configureDependencies,
  );
}
```

`configureDependencies` registers package-owned types. If the host already
registered the same type, check `isRegistered` first.

![Application startup, ensureInitialized lifecycle, and package test setup](assets/lifecycle.png)

### Data layer

Read the getters. Do not take host objects in constructors.

```dart
class CatalogRepository {
  const CatalogRepository();

  Future<List<int>> fetchItems() {
    return dependencies.apiClient.get(config.baseUrl.resolve('/items'));
  }
}
```

UI talks to package DI. Widgets do not read `packageContext`.

## Wire the application

Import the feature barrel. Do not import `package_context`.

```dart
import 'package:catalog/catalog.dart' as catalog;
```

Order:

```
main
  → build host objects
  → init packages that catalog needs
  → catalog.initPackage(config, dependencies)
  → run the app
```

```dart
await catalog.initPackage(
  config: catalog.Config(
    baseUrl: Uri.parse('https://api.example.com'),
    isEnabled: true,
  ),
  dependencies: catalog.Dependencies(
    apiClient: appApiClient,
    session: AppSession(
      auth: auth,
    ),
  ),
);
```

Pass the same host objects you already use. Do not create a second client
"for this package".

The interface lives in the feature package. The implementation lives in the
app.

```dart
class AppSession implements catalog.Session {
  final Auth auth;

  @override
  String? get userId => auth.currentUserId;

  AppSession({
    required this.auth,
  });
}
```

## Tests

Seed the holder before the suite.

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (!packageContext.isInitialized) {
    packageContext.initialize(
      package_context.PackageGraph(
        config: const Config(
          baseUrl: Uri.parse('https://example.test'),
          isEnabled: true,
        ),
        dependencies: Dependencies(
          apiClient: FakeApiClient(),
          session: const FakeSession(
            userId: 'user-1',
          ),
        ),
      ),
    );
  }

  await testMain();
}
```

If a test breaks the graph, call `packageContext.reset()` in `tearDown`.
Otherwise keep one graph for the suite.

## Contract

| API | Behavior |
|---|---|
| `isInitialized` | `true` only when a `PackageGraph` is set |
| getters | `PackageContextNotInitialized` if empty |
| `initialize` | Assigns once. `PackageContextAlreadyInitialized` if already set |
| `refresh` | Replaces the graph in place |
| `ensureInitialized` | No-op, refresh, or initialize, then bind |
| `reset()` | Tests only. Clears the graph |

## Rules

1. The feature package depends on `package_context`. The app does not.
2. One `packageContext` per package.
3. Config holds values. Dependencies hold host objects. Both travel as `PackageGraph`.
4. The public barrel exports `Config`, `Dependencies`, `initPackage`.
5. Data and domain read getters. UI does not.
6. The app calls `initPackage` after every dependency exists.
7. Host adapters live in the app.
8. Do not read `String.fromEnvironment` inside the package.
9. Do not call `initialize` twice. Use `refresh` or `ensureInitialized`.

- Repository: [github.com/pchkauu/package_context](https://github.com/pchkauu/package_context)
- Issues: [github.com/pchkauu/package_context/issues](https://github.com/pchkauu/package_context/issues)
- License: MIT
