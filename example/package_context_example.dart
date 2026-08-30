import 'package:package_context/package_context.dart' as package_context;

// #docregion config
/// Values the host passes into the feature package.
final class Config extends package_context.PackageConfig {
  /// Catalog API root.
  final Uri baseUrl;

  /// Whether the catalog feature is on.
  final bool isEnabled;

  /// Creates a catalog config.
  const Config({
    required this.baseUrl,
    required this.isEnabled,
  });
}
// #enddocregion

/// Host-owned HTTP port.
abstract interface class ApiClient {
  /// Fetches bytes from [url].
  Future<List<int>> get(Uri url);
}

/// Host-owned session.
abstract interface class Session {
  /// Current user id, if any.
  String? get userId;
}

// #docregion dependencies
/// Host objects the package must not create.
final class Dependencies extends package_context.PackageDependencies {
  /// HTTP client from the host.
  final ApiClient apiClient;

  /// Session from the host.
  final Session session;

  /// Creates catalog dependencies.
  const Dependencies({
    required this.apiClient,
    required this.session,
  });
}
// #enddocregion

// #docregion context
/// Process-wide catalog context. Do not export this from the package barrel.
final packageContext = package_context.PackageContext<Config, Dependencies>();

/// Typed config getter for package code.
Config get config => packageContext.config;

/// Typed dependencies getter for package code.
Dependencies get dependencies => packageContext.dependencies;
// #enddocregion

/// Whether the package DI still holds the catalog facade.
var _isRegistered = false;

// #docregion init_package
/// Initializes the catalog package once per process graph.
Future<void> initPackage({
  required Config config,
  required Dependencies dependencies,
}) {
  return packageContext.ensureInitialized(
    graph: package_context.PackageGraph(
      config: config,
      dependencies: dependencies,
    ),
    isBound: _isRegistered,
    bind: () async {
      _isRegistered = true;
    },
  );
}
// #enddocregion

/// Reads the holder. Takes no host objects in the constructor.
class CatalogRepository {
  /// Creates a catalog repository.
  const CatalogRepository();

  /// Loads catalog items for the current session.
  Future<List<int>> fetchItems() {
    return dependencies.apiClient.get(config.baseUrl.resolve('/items'));
  }
}

/// In-memory host client. Uses the session as the "token".
class MemoryApiClient implements ApiClient {
  /// Session whose user id stands in for an auth token.
  final Session session;

  /// Creates a client bound to [session].
  MemoryApiClient({
    required this.session,
  });

  @override
  Future<List<int>> get(Uri url) async {
    return session.userId == 'user-2' ? [2, 2] : [1, 1];
  }
}

/// Host session.
class AppSession implements Session {
  @override
  final String userId;

  /// Creates a session for [userId].
  const AppSession({
    required this.userId,
  });
}

// #docregion host
void main() async {
  const firstSession = AppSession(
    userId: 'user-1',
  );
  await initPackage(
    config: Config(
      baseUrl: Uri.parse('https://api.example.com'),
      isEnabled: true,
    ),
    dependencies: Dependencies(
      apiClient: MemoryApiClient(
        session: firstSession,
      ),
      session: firstSession,
    ),
  );

  print('first launch: ${await const CatalogRepository().fetchItems()}');

  _isRegistered = false;

  const nextSession = AppSession(
    userId: 'user-2',
  );
  await initPackage(
    config: Config(
      baseUrl: Uri.parse('https://api.example.com'),
      isEnabled: true,
    ),
    dependencies: Dependencies(
      apiClient: MemoryApiClient(
        session: nextSession,
      ),
      session: nextSession,
    ),
  );

  print('after refresh: ${await const CatalogRepository().fetchItems()}');
}
// #enddocregion
