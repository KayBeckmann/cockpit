# Cockpit

> **Status: Planung / M0**

Ein selbstgehostetes, datenschutzfreundliches Life-Management-System — „zweites Gehirn + Lebens-Cockpit" in einer Flutter-App.

Alle Lebensbereiche sind **vernetzt** (eine Aufgabe hängt an einem Projekt, einem Kontakt und einer Wiki-Notiz), bleiben aber per **Kontext-Schalter** (Privat / Arbeit / Alles) sauber fokussierbar.

---

## Geplante Module

| Modul | Milestone |
|-------|-----------|
| Aufgaben & GTD-Inbox | M1 |
| Projekte (Kanban + Zeiterfassung) | M1 / M5 |
| Kalender / Termine | M2 |
| Kontext-System (Privat / Arbeit / Alles) | M2 |
| Kontakte & Beziehungspflege | M3 |
| Erinnerungen & n8n-Integration | M3 |
| Finanzen & Budgets | M4 |
| Hobbys & Hobbyprojekte | M5 |
| Obsidian-Integration & Dashboard | M6 |

---

## Tech-Stack

| Schicht | Technologie |
|---------|-------------|
| Frontend | Flutter (Material 3, Riverpod, go_router, Clean Architecture) |
| Lokaler Cache | Drift (SQLite) |
| Backend/API | Dart Frog |
| Datenbank | PostgreSQL |
| Automatisierung | n8n → Matrix/Synapse |
| Lokale KI | Ollama (Qwen3:8b) |

**Plattformen:** Android · Linux · Web · (Windows geplant)

---

## Roadmap

```
M0  Fundament          — Repo, Skeleton, Infra, Entscheidungen
M1  Aufgaben & GTD     — Erstes produktiv nutzbares Modul
M2  Kalender & Cockpit — Tages-Cockpit mit Kontext-System
M3  Kontakte           — Beziehungspflege + Erinnerungen
M4  Finanzen           — Budgets, Konten, Transaktionen
M5  Hobbys             — Kanban, Zeiterfassung, Ressourcen
M6  Integration        — Obsidian-Link, Graph, Ollama, CalDAV
```

Detaillierte Roadmap und Architektur liegen im zugehörigen [Obsidian-Vault](https://github.com/KayBeckmann/obsidian_vault) unter `10_Projects/Cockpit/`.

---

## Kontext-Logik

Jedes Objekt trägt `kontext ∈ {privat, arbeit, beides}`. Ein globaler UI-Schalter filtert die gesamte App. Finanzen sind **hart getrennt** (steuerrechtlich); alle anderen Bereiche weich über den Schalter steuerbar.

---

## Selbst hosten

Deployment-Anleitung folgt mit M0 (Docker Compose für PostgreSQL + Dart Frog Backend).

---

## Lizenz

MIT © 2026 Kay Beckmann
