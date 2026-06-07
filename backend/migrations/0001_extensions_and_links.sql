-- Erstes Schema: Cross-cutting Infrastruktur, die alle Fachmodule nutzen.
-- Feature-Tabellen (tasks, events, ...) kommen mit den jeweiligen
-- Modul-Migrationen ab M1 (siehe Architektur.md).

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Universelle Verknüpfungstabelle — der Schlüssel zum vernetzten System.
CREATE TABLE links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  von_typ TEXT NOT NULL,
  von_id UUID NOT NULL,
  zu_typ TEXT NOT NULL,
  zu_id UUID NOT NULL,
  beziehung TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (von_typ, von_id, zu_typ, zu_id)
);
