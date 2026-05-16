import { drizzle } from "drizzle-orm/neon-http";
import { neon } from "@neondatabase/serverless";
import * as schema from "./schema.js"; // Corrigido para apontar ao arquivo de schema recém-criado

const connectionString =
  process.env.DATABASE_URL ??
  process.env.NEON_DATABASE_URL ??
  process.env.POSTGRES_URL ??
  process.env.POSTGRES_URL_NON_POOLING;

if (!connectionString) {
  throw new Error(
    "Database connection string is not set. Set DATABASE_URL (recommended) or NEON_DATABASE_URL/POSTGRES_URL.",
  );
}

const sql = neon(connectionString);
export const db = drizzle(sql, { schema });
