# package_context

A Dart package that helps define the context and boundaries of packages.
It lets you declare the allowed direction of dependencies between packages
and the application.

## Features

- Declare a package's architectural context: name, role, and allowed dependencies
- Check whether one package may depend on another
- Keep contexts `const` so the dependency graph lives in source

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  package_context: ^1.0.0
```

## Usage

```dart
import 'package:package_context/package_context.dart';

const domain = PackageContext(
  name: 'domain',
  role: PackageRole.domain,
);

const data = PackageContext(
  name: 'data',
  role: PackageRole.data,
  allowedDependencies: {PackageRole.domain},
);

void main() {
  print(data.canDependOn(domain)); // true
  print(domain.canDependOn(data)); // false
}
```

A longer example lives in [`example/`](example/package_context_example.dart).

## Additional information

- Repository: [github.com/pchkauu/package_context](https://github.com/pchkauu/package_context)
- Issues: [github.com/pchkauu/package_context/issues](https://github.com/pchkauu/package_context/issues)
- License: MIT
