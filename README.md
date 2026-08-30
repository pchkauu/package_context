# package_context

Holds one config and one dependency graph for a feature package.

The app initializes the package at startup. After that the package reads typed
`config` and `dependencies`. The app never imports `package_context`.

This is not a DI container. Put host values and host objects here. Keep
repositories, use cases, and blocs in the package's own container.

| Type | Content | Examples |
|---|---|---|
| `PackageConfig` | Values from the host | URL, keys, flags |
| `PackageDependencies` | Objects the package must not create | HTTP client, session, adapters |

One package — one `PackageContext`. It lives as long as the process.

An empty `Config` is fine. The instance is still required.

## Install

Add the dependency to the **feature package**, not to the app:

```yaml
dependencies:
  package_context: ^1.0.0
```

In a monorepo:

```yaml
dependencies:
  package_context:
    path: ../package_context
```

## Wire a feature package

The samples use a fictional `catalog` package.

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

  @override
  List<Object?> get props => [baseUrl, isEnabled];
}
```

No values? Keep an empty config:

```dart
final class Config extends package_context.PackageConfig {
  const Config();

  @override
  List<Object?> get props => [];
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

  @override
  List<Object?> get props => [apiClient, session];
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
- First start → setters, then register.

Do not assign setters twice: they throw `StateError`. Use `refresh`.

```dart
Future<void> initPackage({
  required Config config,
  required Dependencies dependencies,
}) async {
  final isRegistered = getIt.isRegistered<CatalogFacade>();
  if (packageContext.isInitialized && isRegistered) {
    return;
  }

  if (packageContext.isInitialized) {
    packageContext.refresh(config: config, dependencies: dependencies);
  } else {
    packageContext
      ..config = config
      ..dependencies = dependencies;
  }

  if (!isRegistered) {
    await configureDependencies();
  }
}
```

`configureDependencies` registers package-owned types. If the host already
registered the same type, check `isRegistered` first.

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
    session: AppSession(auth: auth),
  ),
);
```

Pass the same host objects you already use. Do not create a second client
"for this package".

The interface lives in the feature package. The implementation lives in the
app.

```dart
class AppSession implements catalog.Session {
  AppSession({required this.auth});

  final Auth auth;

  @override
  String? get userId => auth.currentUserId;
}
```

## Tests

Seed the holder before the suite.

```dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (!packageContext.isInitialized) {
    packageContext.config = const Config(
      baseUrl: Uri.parse('https://example.test'),
      isEnabled: true,
    );
    packageContext.dependencies = Dependencies(
      apiClient: FakeApiClient(),
      session: const FakeSession(userId: 'user-1'),
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
| `isInitialized` | `true` only when both values are set |
| getters | `StateError` if not initialized |
| setters | `StateError` if already initialized |
| `refresh` | Replaces both values in place |
| `reset()` | Tests only. Clears both values |

## Rules

1. The feature package depends on `package_context`. The app does not.
2. One `packageContext` per package.
3. Config holds values. Dependencies hold host objects.
4. The public barrel exports `Config`, `Dependencies`, `initPackage`.
5. Data and domain read getters. UI does not.
6. The app calls `initPackage` after every dependency exists.
7. Host adapters live in the app.
8. Do not read `String.fromEnvironment` inside the package.
9. Do not assign setters twice. Use `refresh` or `reset`.

- Repository: [github.com/pchkauu/package_context](https://github.com/pchkauu/package_context)
- Issues: [github.com/pchkauu/package_context/issues](https://github.com/pchkauu/package_context/issues)
- License: MIT
