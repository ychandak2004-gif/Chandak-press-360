-- Chandak Press 360 Wallet foundation (Cloudflare D1 / SQLite)
-- Amounts are stored as integer paise. Never store currency as floating point.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS agents (
  firebase_uid TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  active INTEGER NOT NULL DEFAULT 1 CHECK (active IN (0,1)),
  discount_percent INTEGER NOT NULL DEFAULT 0 CHECK (discount_percent BETWEEN 0 AND 10),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wallets (
  agent_uid TEXT PRIMARY KEY REFERENCES agents(firebase_uid),
  balance_paise INTEGER NOT NULL DEFAULT 0 CHECK (balance_paise >= 0),
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wallet_transactions (
  id TEXT PRIMARY KEY,
  agent_uid TEXT NOT NULL REFERENCES agents(firebase_uid),
  kind TEXT NOT NULL CHECK (kind IN ('recharge','order_debit','refund','admin_adjustment')),
  amount_paise INTEGER NOT NULL CHECK (amount_paise > 0),
  balance_after_paise INTEGER NOT NULL CHECK (balance_after_paise >= 0),
  reference_type TEXT,
  reference_id TEXT,
  idempotency_key TEXT NOT NULL UNIQUE,
  note TEXT,
  created_by TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS wallet_transactions_agent_date
  ON wallet_transactions(agent_uid, created_at);

CREATE TABLE IF NOT EXISTS recharge_requests (
  id TEXT PRIMARY KEY,
  agent_uid TEXT NOT NULL REFERENCES agents(firebase_uid),
  amount_paise INTEGER NOT NULL CHECK (amount_paise > 0),
  method TEXT NOT NULL CHECK (method IN ('upi_qr','bank_transfer')),
  utr TEXT,
  proof_url TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','verified','rejected')),
  verified_by TEXT,
  verified_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS recharge_requests_agent_status
  ON recharge_requests(agent_uid, status);

CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY,
  agent_uid TEXT NOT NULL REFERENCES agents(firebase_uid),
  product_id TEXT NOT NULL,
  product_snapshot TEXT NOT NULL,
  subtotal_paise INTEGER NOT NULL CHECK (subtotal_paise >= 0),
  discount_percent INTEGER NOT NULL CHECK (discount_percent BETWEEN 0 AND 10),
  discount_paise INTEGER NOT NULL CHECK (discount_paise >= 0),
  payable_paise INTEGER NOT NULL CHECK (payable_paise >= 0),
  status TEXT NOT NULL DEFAULT 'Queued',
  idempotency_key TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS orders_agent_date ON orders(agent_uid, created_at);

CREATE TABLE IF NOT EXISTS payment_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  upi_id TEXT,
  account_holder TEXT,
  bank_name TEXT,
  account_number TEXT,
  ifsc TEXT,
  qr_image_data_url TEXT,
  updated_by TEXT,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
