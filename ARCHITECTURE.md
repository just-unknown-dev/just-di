# Architecture — Just DI

This document describes the internal design of the `just_di` package.

---

## Overview

`just_di` is a lightweight, framework-agnostic dependency injection (DI) library for Dart. It provides:

- Three registration lifetimes: **singleton**, **lazy singleton**, and **factory**.
- A **scoped container** model for request / feature / test isolation.
- A **global facade** (`JustDi`) for ergonomic app-level usage.
- Explicit lifecycle management: `unregister`, `reset`, and `close`.

The library has **no Flutter dependency** and no external Dart packages.

---

## Public API Surface

```
just_di.dart  (library barrel)
├── Resolver               (interface)
├── DiContainer            (core container)
├── DiScope                (child container / scope)
├── JustDi                 (global facade over a singleton DiContainer)
├── InstanceDisposer<T>    (typedef — disposal callback)
└── Di*Exception classes   (error hierarchy)
```

---

## Layer Diagram

```
┌─────────────────────────────────┐
│          JustDi (facade)        │  ← app-level API
│  static wrapper around _global  │
└────────────┬────────────────────┘
             │ delegates to
┌────────────▼────────────────────┐
│         DiContainer             │  ← core implementation
│  _registrations: Map<Key,Reg>   │
│  _parent: DiContainer?          │
└────────────┬────────────────────┘
             │ extended by
┌────────────▼────────────────────┐
│          DiScope                │  ← child scope
│  (adds debugLabel, hides ctor)  │
└─────────────────────────────────┘
```

---

## Core Components

### `Resolver` (interface)

Defined in `resolver.dart`. Declares the read-only contract implemented by `DiContainer`:

| Method | Description |
|--------|-------------|
| `get<T>({instanceName})` | Resolve a required service; throws if missing. |
| `getOrNull<T>({instanceName})` | Resolve an optional service; returns `null` if missing. |
| `isRegistered<T>({instanceName})` | Check whether a type is registered. |

`InstanceDisposer<T>` is also defined here as `typedef InstanceDisposer<T> = void Function(T instance)`.

---

### `DiContainer`

The central class. Holds a `Map<_ServiceKey, _Registration<Object>>` and an optional reference to a parent container.

**Key responsibilities:**

| Responsibility | Implementation detail |
|---|---|
| Registration | `registerSingleton`, `registerLazySingleton`, `registerFactory` each call the private `_register` which guards against duplicates unless `override: true`. |
| Resolution | `_resolve` looks up `_registrations` first; on a miss it walks to `_parent`, enabling scope inheritance. |
| Lifecycle | `unregister` removes a single entry; `reset` removes all; `close` calls `reset` then marks the container as closed. All operations call `_ensureOpen` to prevent use-after-close. |
| Scope creation | `createScope` returns a `DiScope` whose parent is `this`. |

---

### `DiScope`

A `final class` that extends `DiContainer` with a private constructor. Created only via `DiContainer.createScope()`. Adds an optional `debugLabel` for logging/debugging.

Because it extends `DiContainer`, it inherits all registration and resolution methods. Services registered on a scope shadow the parent for that scope's lifetime, but the parent is unaffected when `scope.close()` is called.

---

### `_ServiceKey`

A private value-object keyed on `(Type, String?)`. Two keys are equal when both `type` and `instanceName` match, enabling named registrations for the same type.

---

### `_Registration<T>`

A private class with three named constructors mirroring the three lifetimes:

| Constructor | `kind` | Caches instance? | Dispose callback? |
|---|---|---|---|
| `_Registration.singleton(instance)` | `singleton` | Yes (pre-built) | Optional |
| `_Registration.lazy(factory)` | `lazySingleton` | Yes (on first call) | Optional |
| `_Registration.factory(factory)` | `factory` | No | Never |

`resolve(_ServiceKey)` dispatches on `kind`. Lazy and factory paths go through `_create`, which sets an `_isCreating` guard flag to detect and throw `CircularDependencyException` on re-entrant resolution.

`disposeOwned()` calls the stored `InstanceDisposer` only when a cached instance exists.

---

### `JustDi` (facade)

An `abstract final class` with a single private `static final DiContainer _global`. Every static method delegates to `_global`. No instances can be created.

---

## Exception Hierarchy

```
DiException (base)
├── ServiceNotFoundException        — get<T> with no matching registration
├── DuplicateRegistrationException  — registering same key without override:true
└── CircularDependencyException     — factory calls resolve<T> for its own type
```

All extend `DiException` which implements `Exception` and provides a human-readable `toString`.

---

## Resolution Flow

```
get<T>()
  └─► _resolve(_ServiceKey(T, name))
        ├─ _registrations[key] found?
        │    └─► _Registration.resolve(key)
        │          ├─ singleton  → return _cachedInstance
        │          ├─ lazy       → cached? return it : _create(cache:true)
        │          └─ factory    → _create(cache:false)
        └─ not found → _parent?._resolve(key) → ... → ServiceNotFoundException
```

---

## Scope Lifecycle

```
DiContainer (root / global)
│  registerSingleton<A>(...)
│
└─► createScope()  ──► DiScope (child)
      │  registerSingleton<B>(...)  ← local only
      │
      │  get<A>()   ← resolved from root via _parent chain
      │  get<B>()   ← resolved locally
      │
      └─► close()   ← disposes B, root's A is untouched
```

A scope is intentionally **not** registered inside its parent's map — it is a separate container that holds a reference to its parent for read-only resolution delegation.

---

## Design Decisions

| Decision | Rationale |
|---|---|
| No reflection / `dart:mirrors` | Keeps the library AOT-safe and tree-shakeable. All wiring is done explicitly in code. |
| Parent chain for scope inheritance | Simple and allocation-cheap; avoids copying parent registrations into child maps. |
| `_isCreating` flag instead of a resolution stack | Sufficient for the synchronous, single-threaded use-case; avoids allocating a stack per resolve call. |
| `abstract final class JustDi` | Prevents subclassing and instantiation; communicates that this is a pure namespace. |
| `override: false` default | Forces explicit opt-in to replacement, making accidental double-registration a hard error rather than a silent bug. |
| Dispose order reversed in `reset` | Mirrors typical DI teardown order: last registered, first disposed. |
