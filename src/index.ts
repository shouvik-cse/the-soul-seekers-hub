export interface Env {
  DB: D1Database;
  ALLOWED_ORIGIN?: string;
}

const json = (data: unknown, status = 200, origin = "*") =>
  new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "access-control-allow-origin": origin,
      "access-control-allow-methods": "GET,POST,OPTIONS",
      "access-control-allow-headers": "content-type"
    }
  });

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const origin = env.ALLOWED_ORIGIN || "*";

    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "access-control-allow-origin": origin,
          "access-control-allow-methods": "GET,POST,OPTIONS",
          "access-control-allow-headers": "content-type"
        }
      });
    }

    if (url.pathname === "/api/health") {
      const result = await env.DB.prepare("SELECT 1 AS ok").first();
      return json({ ok: result?.ok === 1, service: "The Soul Seeker's Hub API" }, 200, origin);
    }

    if (url.pathname === "/api/categories" && request.method === "GET") {
      const rows = await env.DB.prepare(
        "SELECT category, COUNT(*) AS product_count FROM products WHERE product_type='component' GROUP BY category ORDER BY category"
      ).all();
      return json(rows.results, 200, origin);
    }

    if (url.pathname === "/api/products" && request.method === "GET") {
      const type = url.searchParams.get("type");
      const category = url.searchParams.get("category");
      const search = url.searchParams.get("q");
      const limit = Math.min(Math.max(Number(url.searchParams.get("limit") || 100), 1), 250);
      const offset = Math.max(Number(url.searchParams.get("offset") || 0), 0);
      const clauses: string[] = [];
      const values: (string | number)[] = [];
      if (type === "component" || type === "laptop") {
        clauses.push("p.product_type=?"); values.push(type);
      }
      if (category) {
        clauses.push("p.category=?"); values.push(category);
      }
      if (search) {
        clauses.push("(p.name LIKE ? OR p.model LIKE ? OR p.specifications LIKE ?)");
        values.push(`%${search}%`, `%${search}%`, `%${search}%`);
      }
      const where = clauses.length ? "WHERE " + clauses.join(" AND ") : "";
      const stmt = env.DB.prepare(`
        SELECT p.id,p.product_type,p.category,p.name,p.model,p.specifications,
          (SELECT MIN(po.price_bdt) FROM retailer_listings rl
            JOIN price_observations po ON po.listing_id=rl.id
            WHERE rl.product_id=p.id AND rl.active=1 AND po.is_valid=1) AS verified_lowest_price_bdt
        FROM products p ${where}
        ORDER BY p.category,p.name LIMIT ? OFFSET ?
      `).bind(...values, limit, offset);
      const rows = await stmt.all();
      return json({ results: rows.results, limit, offset }, 200, origin);
    }

    if (url.pathname.startsWith("/api/products/") && request.method === "GET") {
      const id = decodeURIComponent(url.pathname.split("/").pop() || "");
      const product = await env.DB.prepare(
        "SELECT * FROM products WHERE id=?"
      ).bind(id).first();
      if (!product) return json({ error: "Product not found" }, 404, origin);
      const listings = await env.DB.prepare(`
        SELECT r.name AS retailer, rl.product_url, rl.exact_match_status,
          po.price_bdt, po.stock_status, po.observed_at, po.is_valid
        FROM retailer_listings rl
        JOIN retailers r ON r.id=rl.retailer_id
        LEFT JOIN price_observations po ON po.id=(
          SELECT id FROM price_observations WHERE listing_id=rl.id ORDER BY observed_at DESC LIMIT 1
        )
        WHERE rl.product_id=? AND rl.active=1
        ORDER BY po.price_bdt ASC
      `).bind(id).all();
      return json({ product, listings: listings.results }, 200, origin);
    }

    return json({ error: "Route not found" }, 404, origin);
  }
};
