import 'package:package_context/package_context.dart';

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

void main() {
  print('data -> domain: ${data.canDependOn(domain)}');
  print('domain -> data: ${domain.canDependOn(data)}');
  print('app -> data: ${app.canDependOn(data)}');
}
