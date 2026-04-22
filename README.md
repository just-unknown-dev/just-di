# Just DI

A lightweight, framework-agnostic dependency injection package for Dart and Flutter.

## Features

- Global service registration
- Singleton, lazy singleton, and factory support
- Scoped overrides for tests and feature isolation
- Explicit reset and disposal behavior

## Quick Start

```dart
import 'package:just_di/just_di.dart';

final api = ApiClient();
JustDi.registerSingleton<ApiClient>(api);

final scope = JustDi.createScope();
scope.registerLazySingleton<AuthService>(() => AuthService(scope.get<ApiClient>()));

final auth = scope.get<AuthService>();
scope.close();
```
