# The Soul Seeker's Hub

Bangladesh-focused PC component catalogue, PC builder, build recommendation and laptop finder.

## Current implementation

- Preserves the latest approved frontend in `public/index.html`.
- Extracts 446 component records and 16 laptop records into JSON source files.
- Defines a Cloudflare D1 schema for products, retailers, exact retailer listings, price observations, benchmarks, compatibility rules and saved builds.
- Includes a deterministic catalogue importer.
- Includes a Cloudflare Worker API for health, categories, product search and product detail.
- Historical prices imported from the existing catalogue are deliberately marked unverified and are not used as verified live prices.

## Requirements

- Node.js LTS
- Python 3
- Cloudflare account
- GitHub account

## Local catalogue import test

```bash
python scripts/import_catalogue.py local.sqlite
```

This creates a local SQLite database and imports the existing catalogue. It does not deploy anything.

## Deploy the D1 API

1. Install dependencies with `npm install`.
2. Create the D1 database: `npx wrangler d1 create the-soul-seekers-hub`.
3. Copy the returned database ID into `wrangler.toml`.
4. Apply the schema: `npx wrangler d1 migrations apply the-soul-seekers-hub --remote`.
5. Import the catalogue using `npx wrangler d1 execute the-soul-seekers-hub --remote --file=data/seed.sql`.
6. Deploy the Worker with `npx wrangler deploy`.

## Important pricing status

No retailer API, feed or automated page collector is connected yet. The imported price records are historical catalogue snapshots marked invalid for verified-price selection. Do not describe them as live prices. Retailer collection must be authorised and must respect terms, robots restrictions and rate limits.

## Security

Never commit passwords, API tokens, `.dev.vars` or private keys.
