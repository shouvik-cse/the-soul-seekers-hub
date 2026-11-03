#!/usr/bin/env python3
import json, pathlib, sqlite3, sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
DB = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "local.sqlite"
components = json.loads((ROOT / "data/components.json").read_text(encoding="utf-8"))
laptops = json.loads((ROOT / "data/laptops.json").read_text(encoding="utf-8"))

con = sqlite3.connect(DB)
con.executescript((ROOT / "migrations/0001_initial_schema.sql").read_text(encoding="utf-8"))

def retailer_id(name):
    con.execute("INSERT OR IGNORE INTO retailers(name) VALUES (?)", (name or "Unspecified",))
    return con.execute("SELECT id FROM retailers WHERE name=?", (name or "Unspecified",)).fetchone()[0]

def add_product(pid, ptype, category, name, model, specs, price, retailer, url, checked):
    con.execute("""
      INSERT OR REPLACE INTO products(id,product_type,category,name,model,specifications,updated_at)
      VALUES(?,?,?,?,?,?,CURRENT_TIMESTAMP)
    """, (pid, ptype, category, name, model, json.dumps(specs, ensure_ascii=False)))
    if url and price:
        rid = retailer_id(retailer)
        con.execute("""
          INSERT OR IGNORE INTO retailer_listings(product_id,retailer_id,product_url,exact_match_status)
          VALUES(?,?,?,'unverified')
        """, (pid, rid, url))
        lid = con.execute("""
          SELECT id FROM retailer_listings WHERE product_id=? AND retailer_id=? AND product_url=?
        """, (pid, rid, url)).fetchone()[0]
        con.execute("""
          INSERT INTO price_observations(listing_id,price_bdt,stock_status,source_type,is_valid,notes)
          VALUES(?,?,'unknown','catalogue_snapshot',0,?)
        """, (lid, int(price), checked or "Imported catalogue snapshot; not live verified"))

for p in components:
    specs = {k:v for k,v in p.items() if k not in {"id","cat","name","price","retailer","url","checked"}}
    add_product(p["id"], "component", p.get("cat","Other"), p["name"], None, specs,
                p.get("price"), p.get("retailer"), p.get("url"), p.get("checked"))

for i,p in enumerate(laptops):
    pid = "laptop-" + str(i+1).zfill(3)
    specs = {k:v for k,v in p.items() if k not in {"name","model","price","retailer","url","checked"}}
    add_product(pid, "laptop", "Laptop", p["name"], p.get("model"), specs,
                p.get("price"), p.get("retailer"), p.get("url"), p.get("checked"))

con.commit()
print(f"Imported {len(components)} component records and {len(laptops)} laptop records into {DB}")
