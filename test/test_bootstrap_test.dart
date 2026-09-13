import 'package:test/test.dart';

import '../example/package_context_example.dart' as catalog;
import '../example/test_bootstrap.dart';

void main() {
  setUp(initializeTestContext);
  tearDown(catalog.packageContext.reset);

  test('bootstrap provides usable config and in-memory dependencies', () async {
    expect(catalog.config.baseUrl, Uri.parse('https://example.test'));
    expect(catalog.config.isEnabled, isTrue);
    expect(catalog.dependencies.session.userId, 'user-1');
    expect(await const catalog.CatalogRepository().fetchItems(), [1, 1]);
  });

  test('bootstrap restores fresh host objects after reset', () {
    final first = catalog.dependencies;
    catalog.packageContext.reset();
    initializeTestContext();

    expect(catalog.dependencies, isNot(same(first)));
    expect(catalog.dependencies.apiClient, isNot(same(first.apiClient)));
    expect(catalog.config.baseUrl, Uri.parse('https://example.test'));
  });
}
