## 1.0.0

Initial stable release.

### Added

- `DiContainer` — core dependency injection container with `registerSingleton`, `registerLazySingleton`, and `registerFactory`.
- `DiScope` — child container created via `DiContainer.createScope()` for request, feature, or test isolation; inherits parent registrations via parent-chain resolution.
- `JustDi` — global static facade backed by a shared `DiContainer` for app-level service registration.
- `Resolver` interface — read-only contract exposing `get<T>`, `getOrNull<T>`, and `isRegistered<T>`.
- Named instance support via the optional `instanceName` parameter on all registration and resolution methods.
- `override` flag on all registration methods to allow explicit replacement of an existing registration.
- Optional `InstanceDisposer<T>` callback on singleton and lazy-singleton registrations, called automatically on `unregister`, `reset`, and `close`.
- `unregister<T>` — removes a single registration with optional disposal.
- `reset` — removes all registrations from a container with optional disposal (in reverse registration order).
- `close` — disposes and permanently seals a container or scope.
- `CircularDependencyException`, `DuplicateRegistrationException`, and `ServiceNotFoundException` error types.
