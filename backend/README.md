# Cockpit Backend

API für [Cockpit](../README.md), gebaut mit [Dart Frog](https://dart-frog.dev).

## Struktur

- `routes/` — API-Endpunkte (dateibasiertes Routing, `_middleware.dart` je Verzeichnis)
- `migrations/` — SQL-Migrationen für PostgreSQL, sequenziell nummeriert

## Entwicklung

```sh
dart_frog dev
```

Konfiguration (DB-Verbindung, JWT-Secret) kommt aus `.env` im Repo-Root
(siehe `../.env.example`) — keine Secrets im Code oder Repo.
