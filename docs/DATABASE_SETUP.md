# Database setup

## 1. Create the database

```bash
npx wrangler d1 create the-soul-seekers-hub
```

Copy the returned database ID into `wrangler.toml`.

## 2. Apply the schema

```bash
npx wrangler d1 migrations apply the-soul-seekers-hub --remote
```

## 3. Import the existing catalogue

The existing HTML contained 446 component records and 16 laptop records. They are preserved in `data/components.json` and `data/laptops.json`.

The Python importer can create a local SQLite database for validation:

```bash
python scripts/import_catalogue.py local.sqlite
```

For the remote D1 database, run the data-only seed file with `npx wrangler d1 execute the-soul-seekers-hub --remote --file=data/seed.sql`. Do not import the old price values as verified current prices. The seed importer marks all imported historical observations `is_valid=0`.

## 4. Bind the API

The Worker expects a D1 binding named `DB`, configured in `wrangler.toml`.

## 5. API routes

- `GET /api/health`
- `GET /api/categories`
- `GET /api/products?type=component&category=CPU&q=Ryzen&limit=100&offset=0`
- `GET /api/products?type=laptop`
- `GET /api/products/:id`

## Next integration task

Connect the frontend's product loading functions to these endpoints. Keep a temporary local fallback until API deployment is confirmed.
