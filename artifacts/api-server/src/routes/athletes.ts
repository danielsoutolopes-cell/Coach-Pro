import { Router, type Request, type Response } from 'express';
import { db, eq, sql } from '@workspace/db';
import { athletesTable } from '@workspace/db/schema';
import multer from 'multer';

export const athletesRouter = Router();

// Configura o multer para salvar temporariamente os uploads na pasta 'uploads/'
const upload = multer({ dest: 'uploads/' });

// 1. GET /profile - Busca o perfil e estoque de géis do Atleta
athletesRouter.get('/:id/profile', async (req: Request, res: Response) => {
  try {
    const id = parseInt(req.params.id as string);
    const rows = await db.select().from(athletesTable).where(eq(athletesTable.id, id)).limit(1);
    const athlete = rows[0];
    
    if (!athlete) {
      res.status(404).json({ error: 'Athlete not found' });
      return;
    }

    res.json({
      id: athlete.id.toString(),
      name: athlete.name || 'CEO',
      // O campo gelInventory pode não estar mapeado formalmente no schema yet, 
      // usamos um fallback seguro caso não exista.
      gel_inventory: (athlete as any).gelInventory ?? 10, 
      races: [], // Retorne as provas do banco aqui no futuro
    });
  } catch (err) {
    console.error('[API] Erro ao buscar perfil:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// 2. PATCH /gels - Atualiza o estoque de géis (Atualização Otimista)
athletesRouter.patch('/:id/gels', async (req: Request, res: Response) => {
  try {
    const id = parseInt(req.params.id as string);
    const { gel_inventory } = req.body;
    
    // Usamos raw SQL para injetar direto na coluna correta no Postgres
    await db.execute(sql`UPDATE procoach_athletes SET gel_inventory = ${gel_inventory} WHERE id = ${id}`);
    res.json({ success: true, gel_inventory });
  } catch (err) {
    console.error('[API] Erro ao atualizar géis:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// 3. GET /shoes - Retorna a Rotação de Tênis
athletesRouter.get('/:id/shoes', async (req: Request, res: Response) => {
  try {
    // TODO: Criar a tabela `procoach_shoes`. Por enquanto, enviamos o Mock 
    // para o app não quebrar e mostrar algo na tela.
    res.json([
      { id: '1', nickname: 'Novablast 3', brand: 'Asics', initial_km: 450, target_km: 600, is_active: true },
      { id: '2', nickname: 'Vaporfly 2', brand: 'Nike', initial_km: 350, target_km: 400, is_active: true }
    ]);
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// 4. GET /workouts/today - Lê da tabela plan_sessions a missão do dia
athletesRouter.get('/:id/workouts/today', async (req: Request, res: Response) => {
  try {
    const id = parseInt(req.params.id as string);
    const today = new Date().toLocaleDateString("en-CA", { timeZone: "America/Sao_Paulo" });
    
    const rows = await db.execute(sql`
      SELECT session_date, activity, pace_target, structure, planned_km
      FROM procoach_plan_sessions
      WHERE athlete_id = ${id} AND session_date = ${today}
      LIMIT 1
    `) as { rows: any[] };
    
    const s = rows.rows[0];
    if (!s) {
      res.status(404).json(null); // Retorna 404 (Descanso)
      return;
    }

    res.json({
      id: s.session_date,
      date: s.session_date,
      activity: s.activity,
      pace_alvo: s.pace_target,
      distancia_km: s.planned_km,
      estrutura: s.structure,
      status: 'open',
      shoe_id: null
    });
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// 5. GET /bioimpedance/latest - Busca o último registro de biometria lançado
athletesRouter.get('/:id/bioimpedance/latest', async (req: Request, res: Response) => {
  try {
    const id = parseInt(req.params.id as string);
    const rows = await db.execute(sql`
      SELECT weight_kg, body_fat_pct, muscle_mass_kg
      FROM procoach_bioimpedance
      WHERE athlete_id = ${id}
      ORDER BY entry_date DESC
      LIMIT 1
    `) as { rows: any[] };
    
    const b = rows.rows[0];
    if (!b) {
      res.status(404).json(null);
      return;
    }

    res.json({
      weight_kg: Number(b.weight_kg),
      body_fat_pct: Number(b.body_fat_pct),
      muscle_mass_kg: Number(b.muscle_mass_kg)
    });
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// 6. POST /bioimpedance/upload - Recebe o PDF vindo do Flutter
athletesRouter.post('/:id/bioimpedance/upload', upload.single('file'), async (req: Request, res: Response) => {
  try {
    const id = parseInt(req.params.id as string);
    if (!req.file) {
      res.status(400).json({ error: 'No file uploaded' });
      return;
    }

    console.log(`📄 Recebido PDF do atleta ${id}: ${req.file.originalname}`);
    
    // TODO: Enviar o caminho (req.file.path) para a API de Vision do Gemini
    // Extrair o JSON e inserir na tabela `procoach_bioimpedance`.
    
    res.json({ success: true, message: 'Upload concluído e em processamento.' });
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// 7. GET /compliance/week - Retorna os dados da semana atual para o gráfico (Segunda a Domingo)
athletesRouter.get('/:id/compliance/week', async (req: Request, res: Response) => {
  try {
    const id = parseInt(req.params.id as string);

    // Retorna para a segunda-feira atual (fuso horário SP)
    const nowSp = new Date(new Date().toLocaleString("en-US", { timeZone: "America/Sao_Paulo" }));
    const day = nowSp.getDay();
    const diff = day === 0 ? 6 : day - 1; 
    const monday = new Date(nowSp);
    monday.setDate(nowSp.getDate() - diff);

    // Gera o array com os 7 dias da semana (ex: ['2026-05-11', ..., '2026-05-17'])
    const days = Array.from({ length: 7 }).map((_, i) => {
      const d = new Date(monday);
      d.setDate(monday.getDate() + i);
      return d.toLocaleDateString("en-CA", { timeZone: "America/Sao_Paulo" });
    });

    const from = days[0];
    const to = days[6];

    const planned = await db.execute(sql`
      SELECT session_date, COALESCE(SUM(planned_km), 0)::int AS planned_km
      FROM procoach_plan_sessions
      WHERE athlete_id = ${id} AND session_date >= ${from} AND session_date <= ${to}
      GROUP BY session_date
    `) as { rows: Array<{ session_date: string; planned_km: number }> };

    const completed = await db.execute(sql`
      SELECT entry_date, COALESCE(SUM(distance_km), 0)::int AS completed_km
      FROM procoach_workout_entries
      WHERE athlete_id = ${id} AND entry_date >= ${from} AND entry_date <= ${to}
      GROUP BY entry_date
    `) as { rows: Array<{ entry_date: string; completed_km: number }> };

    const plannedMap = new Map(planned.rows.map(r => [r.session_date, Number(r.planned_km)]));
    const completedMap = new Map(completed.rows.map(r => [r.entry_date, Number(r.completed_km)]));

    // Estrutura pronta para o Flutter (fl_chart) desenhar as 7 barras
    const result = days.map((date, index) => ({
      dayIndex: index,
      date: date,
      plannedKm: plannedMap.get(date) ?? 0,
      completedKm: completedMap.get(date) ?? 0
    }));

    res.json(result);
  } catch (err) {
    console.error('[API] Erro ao buscar compliance:', err);
    res.status(500).json({ error: 'Internal Server Error' });
  }
});