-- Benutzer für die JWT-Authentifizierung. Cockpit ist als persönliches
-- System ausgelegt — die Tabelle hält trotzdem mehrere Konten offen,
-- falls später z.B. ein Familienmitglied Zugriff bekommen soll.

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
