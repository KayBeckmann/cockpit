-- GTD-Kern (M1): Aufgaben und Projekte. `kontext` trägt jede fachliche
-- Entität — globaler Schalter (privat/arbeit/beides) filtert die App.

CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titel TEXT NOT NULL,
  typ TEXT,
  status TEXT NOT NULL DEFAULT 'aktiv',
  fortschritt SMALLINT NOT NULL DEFAULT 0,
  meilensteine JSONB,
  ressourcen JSONB,
  kontext TEXT NOT NULL,
  obsidian_uri TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- `kontext` ist hier (anders als bei den übrigen Entitäten) NULLABLE:
-- Quick-Capture legt Tasks bewusst "ohne Kontext" in die Inbox, GTD-Triage
-- ordnet sie später ein (siehe Roadmap M1, Quick-Capture).
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titel TEXT NOT NULL,
  beschreibung TEXT,
  deadline TIMESTAMPTZ,
  prioritaet SMALLINT,
  status TEXT NOT NULL DEFAULT 'inbox',
  projekt_id UUID REFERENCES projects (id) ON DELETE SET NULL,
  kontext TEXT,
  wiederholung JSONB,
  energie_level TEXT,
  tags TEXT[],
  teilaufgaben JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX tasks_status_idx ON tasks (status);
CREATE INDEX tasks_kontext_idx ON tasks (kontext);
CREATE INDEX tasks_projekt_id_idx ON tasks (projekt_id);
