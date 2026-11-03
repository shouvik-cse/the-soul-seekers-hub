PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS products (
  id TEXT PRIMARY KEY,
  product_type TEXT NOT NULL CHECK (product_type IN ('component','laptop')),
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  model TEXT,
  specifications TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);

CREATE TABLE IF NOT EXISTS retailers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  website TEXT,
  active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS retailer_listings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  retailer_id INTEGER NOT NULL REFERENCES retailers(id),
  product_url TEXT NOT NULL,
  retailer_sku TEXT,
  exact_match_status TEXT NOT NULL DEFAULT 'unverified'
    CHECK (exact_match_status IN ('verified','probable','unverified','rejected')),
  last_checked_at TEXT,
  active INTEGER NOT NULL DEFAULT 1,
  UNIQUE(product_id, retailer_id, product_url)
);

CREATE INDEX IF NOT EXISTS idx_listings_product ON retailer_listings(product_id);

CREATE TABLE IF NOT EXISTS price_observations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  listing_id INTEGER NOT NULL REFERENCES retailer_listings(id) ON DELETE CASCADE,
  price_bdt INTEGER NOT NULL CHECK (price_bdt > 0),
  stock_status TEXT NOT NULL DEFAULT 'unknown'
    CHECK (stock_status IN ('in_stock','out_of_stock','preorder','unknown')),
  source_type TEXT NOT NULL DEFAULT 'catalogue_snapshot'
    CHECK (source_type IN ('official_api','official_feed','permitted_page_check','manual','catalogue_snapshot')),
  observed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  is_valid INTEGER NOT NULL DEFAULT 0,
  notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_prices_listing_time ON price_observations(listing_id, observed_at DESC);

CREATE TABLE IF NOT EXISTS benchmarks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  workload TEXT NOT NULL,
  score REAL NOT NULL CHECK (score > 0),
  source_url TEXT,
  source_name TEXT,
  verified_at TEXT,
  UNIQUE(product_id, workload, source_name)
);

CREATE TABLE IF NOT EXISTS compatibility_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  rule_type TEXT NOT NULL,
  subject_product_id TEXT REFERENCES products(id) ON DELETE CASCADE,
  related_product_id TEXT REFERENCES products(id) ON DELETE CASCADE,
  rule_data TEXT NOT NULL DEFAULT '{}',
  verification_status TEXT NOT NULL DEFAULT 'unverified'
    CHECK (verification_status IN ('verified','unverified','conflict')),
  source_url TEXT,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS builds (
  id TEXT PRIMARY KEY,
  budget_bdt INTEGER NOT NULL,
  use_case TEXT NOT NULL,
  selected_cpu_id TEXT,
  selected_gpu_id TEXT,
  components_json TEXT NOT NULL,
  total_bdt INTEGER NOT NULL,
  validation_status TEXT NOT NULL DEFAULT 'unverified',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS collection_runs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  retailer_id INTEGER REFERENCES retailers(id),
  started_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  finished_at TEXT,
  status TEXT NOT NULL DEFAULT 'running',
  products_checked INTEGER NOT NULL DEFAULT 0,
  error_message TEXT
);
