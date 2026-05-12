import { Router, type IRouter, type Request, type Response } from "express";
import { eq, and, sql } from "@workspace/db";
import { db } from "@workspace/db";
import {
  shoesTable,
} from "@workspace/db/schema";
import { ensureShoesTables, getOrCreateMonoAthleteId } from "./migrations";

const router: IRouter = Router();

router.get("/procoach/me/shoes", async (_req: Request, res: Response) => {
    const athleteId = await getOrCreateMonoAthleteId();
    await ensureShoesTables();
  
    const rows = await db.execute(sql`
      SELECT
        s.id,
        s.nickname,
        s.brand,
        s.model,
        s.start_date,
        s.initial_km,
        s.target_km,
        s.retired_at,
        s.created_at,
        s.updated_at,
        (s.initial_km + COALESCE(SUM(w.distance_km), 0))::int AS km_total,
        MAX(w.entry_date) AS last_used_at
      FROM procoach_shoes s
      LEFT JOIN procoach_workout_entries w
        ON w.athlete_id = s.athlete_id AND w.shoe_id = s.id
      WHERE s.athlete_id = ${athleteId}
      GROUP BY s.id
      ORDER BY (s.retired_at IS NULL) DESC, s.retired_at DESC NULLS LAST, s.updated_at DESC
    `) as { rows: Array<Record<string, unknown>> };
  
    res.json({ shoes: rows.rows });
  });
  
  router.post("/procoach/me/shoes", async (req: Request, res: Response) => {
    const athleteId = await getOrCreateMonoAthleteId();
    await ensureShoesTables();
    const body = req.body as {
      nickname?: string;
      brand?: string | null;
      model?: string | null;
      startDate?: string | null;
      initialKm?: number | null;
      targetKm?: number | null;
    };
  
    const nickname = String(body.nickname ?? "").trim();
    if (!nickname) {
      res.status(400).json({ error: "nickname é obrigatório" });
      return;
    }
  
    const initialKm = Math.max(0, Math.round(Number(body.initialKm ?? 0)));
    const targetKm = Math.max(1, Math.round(Number(body.targetKm ?? 500)));
    const startDate = body.startDate ? String(body.startDate).trim() : null;
    const brand = body.brand ? String(body.brand).trim() : null;
    const model = body.model ? String(body.model).trim() : null;
  
    const [created] = await db
      .insert(shoesTable)
      .values({
        athleteId,
        nickname,
        brand,
        model,
        startDate,
        initialKm,
        targetKm,
        updatedAt: new Date(),
      })
      .returning();
  
    res.json({ shoe: created });
  });
  
  router.put("/procoach/me/shoes/:id", async (req: Request, res: Response) => {
    const athleteId = await getOrCreateMonoAthleteId();
    await ensureShoesTables();
    const id = Number(req.params.id);
    if (!Number.isFinite(id)) {
      res.status(400).json({ error: "id inválido" });
      return;
    }
  
    const body = req.body as {
      nickname?: string;
      brand?: string | null;
      model?: string | null;
      startDate?: string | null;
      initialKm?: number | null;
      targetKm?: number | null;
    };
  
    const patch: Record<string, unknown> = { updatedAt: new Date() };
    if (body.nickname !== undefined) patch.nickname = String(body.nickname ?? "").trim();
    if (body.brand !== undefined) patch.brand = body.brand ? String(body.brand).trim() : null;
    if (body.model !== undefined) patch.model = body.model ? String(body.model).trim() : null;
    if (body.startDate !== undefined) patch.startDate = body.startDate ? String(body.startDate).trim() : null;
    if (body.initialKm !== undefined) patch.initialKm = Math.max(0, Math.round(Number(body.initialKm ?? 0)));
    if (body.targetKm !== undefined) patch.targetKm = Math.max(1, Math.round(Number(body.targetKm ?? 500)));
  
    const [updated] = await db
      .update(shoesTable)
      .set(patch as any)
      .where(and(eq(shoesTable.id, id), eq(shoesTable.athleteId, athleteId)) as any)
      .returning();
  
    if (!updated) {
      res.status(404).json({ error: "Tênis não encontrado" });
      return;
    }
    res.json({ shoe: updated });
  });
  
  router.post("/procoach/me/shoes/:id/archive", async (req: Request, res: Response) => {
    const athleteId = await getOrCreateMonoAthleteId();
    await ensureShoesTables();
    const id = Number(req.params.id);
    if (!Number.isFinite(id)) {
      res.status(400).json({ error: "id inválido" });
      return;
    }
    const [updated] = await db
      .update(shoesTable)
      .set({ retiredAt: new Date(), updatedAt: new Date() })
      .where(and(eq(shoesTable.id, id), eq(shoesTable.athleteId, athleteId)) as any)
      .returning();
    if (!updated) {
      res.status(404).json({ error: "Tênis não encontrado" });
      return;
    }
    res.json({ shoe: updated });
  });
  
  export default router;