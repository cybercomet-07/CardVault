# CardVault – Project Structure

Production-ready Flutter folder structure with **clean architecture**: domain, data, presentation, plus core, services, and reusable widgets.

---

## Root

```
CardVault/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   ├── domain/
│   ├── data/
│   ├── services/
│   ├── presentation/
│   └── injection/
├── pubspec.yaml
└── STRUCTURE.md
```

---

## `lib/core/`

App-wide shared code. No business logic.

| Path | Purpose |
|------|--------|
| `constants/` | `AppConstants`, string/route keys |
| `theme/` | `AppTheme` (light/dark) |
| `utils/` | Validators, formatters, helpers |
| `errors/` | `AppException`, `Failure` |
| `router/` | Route names, `AppRouter` (or go_router config) |
| `core.dart` | Barrel export for `core/` |

---

## `lib/domain/`

**Clean architecture – inner layer.** Pure business rules, no Flutter or Firebase.

| Path | Purpose |
|------|--------|
| `entities/` | `UserEntity`, `CardEntity` (plain Dart) |
| `repositories/` | Abstract contracts: `AuthRepository`, `CardRepository` |
| `domain.dart` | Barrel export |

---

## `lib/data/`

**Clean architecture – data layer.** Implements domain contracts, handles DTOs and I/O.

| Path | Purpose |
|------|--------|
| `models/` | `UserModel`, `CardModel` (from/to Firestore, extend entities) |
| `datasources/` | Abstract: `AuthRemoteDataSource`, `CardRemoteDataSource`, `StorageRemoteDataSource`, `OcrDataSource` |
| `repositories/` | `AuthRepositoryImpl`, `CardRepositoryImpl` (use datasources, return entities) |
| `data.dart` | Barrel export |

---

## `lib/services/`

Concrete wrappers around Firebase / ML Kit. Used by data layer (datasources).

| File | Purpose |
|------|--------|
| `auth_service.dart` | Firebase Auth (login, register, signOut) |
| `firestore_service.dart` | Firestore CRUD for cards |
| `storage_service.dart` | Firebase Storage for card images |
| `ocr_service.dart` | ML Kit (mobile) + web fallback |
| `services.dart` | Barrel export |

---

## `lib/presentation/`

**Clean architecture – UI layer.** Screens, widgets, and state only.

### Screens (by feature)

| Path | Screens |
|------|--------|
| `screens/auth/` | `LoginScreen`, `RegisterScreen` |
| `screens/home/` | `HomeScreen` |
| `screens/cards/` | `CardListScreen`, `CardDetailScreen`, `AddCardScreen` |
| `screens/scanner/` | `CaptureScreen` |
| `screens/screens.dart` | Barrel export |

### Reusable widgets

| Path | Purpose |
|------|--------|
| `widgets/common/` | `AppButton`, `AppTextField`, `LoadingIndicator` |
| `widgets/card/` | `CardTile`, `CardPreview` |
| `widgets/widgets.dart` | Barrel export |

### State

| Path | Purpose |
|------|--------|
| `state/auth/` | `AuthCubit` (auth state) |
| `state/cards/` | `CardsCubit` (list/search) |
| `state/state.dart` | Barrel export |

Use Bloc/Cubit/Provider as preferred; place state classes here and keep screens thin.

### Barrel

- `presentation.dart` – exports `screens`, `state`, `widgets`.

---

## `lib/injection/`

Dependency injection (e.g. `get_it`, `injectable`).

- Register services, datasources, repositories, and cubits.
- Call `configureDependencies()` from `main.dart` before `runApp`.

---

## Dependency flow (clean architecture)

- **Presentation** → **Domain** (repository interfaces) and **Core** (theme, router, utils).
- **Domain** → nothing (only entities and abstract repos).
- **Data** → **Domain** (entities, repo interfaces) and **Services** or concrete datasources.
- **Services** → Firebase/ML Kit SDKs only.

---

## Imports

- Prefer barrel imports: `import 'package:card_vault/domain/domain.dart';`
- Screens import: `presentation/screens.dart` or `presentation/widgets.dart`, `presentation/state.dart` as needed.
- Keep `app.dart` / `main.dart` minimal; router and theme can live in `core/`.

This structure gives clear **separation of screens**, **services**, **models**, **reusable widgets**, and **clean architecture** layers and is ready for production use.
