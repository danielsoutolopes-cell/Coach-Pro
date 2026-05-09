import { Race } from "./schema";
// api.ts
import Constants from "expo-constants";

// -----------------------------------------------------------------------------
// MOTOR DE COMUNICAÇÃO PROCOACH OS V5.1
// Arquitetura Sequencial: Comunicação Blindada com o Render
// -----------------------------------------------------------------------------

// Prioriza a URL fornecida via variável de ambiente (ex: .env)
// No Expo, use EXPO_PUBLIC_API_URL para o ambiente de produção
const API_URL = process.env.EXPO_PUBLIC_API_URL ?? "https://procoach-os-api.onrender.com";

if (!process.env.EXPO_PUBLIC_API_URL) {
  console.warn("[ALERTA TÁTICO] EXPO_PUBLIC_API_URL não definida. As requisições podem falhar ou usar o endereço incorreto.");
}

const BASE = `${API_URL}/api`;

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const url = `${BASE}${path}`;
  
  try {
    const res = await fetch(url, {
      headers: { "Content-Type": "application/json", ...options.headers },
      ...options,
    });
    
    if (!res.ok) {
      const text = await res.text().catch(() => "");
      throw new Error(`API ${options.method ?? "GET"} ${path} → ${res.status}: ${text}`);
    }
    return res.json() as Promise<T>;
  } catch (error) {
    console.error(`[ALERTA TÁTICO] Falha na comunicação com o Cérebro: ${url}`, error);
    throw error;
  }
}

// -----------------------------------------------------------------------------
// INTERFACES (ANATOMIA DOS DADOS E REGRAS DE OURO)
// -----------------------------------------------------------------------------

export interface AthletePayload {
  deviceId: string;
  name?: string;
  // Regra de Ouro: Foco absoluto na Prova Alvo
  targetRaceName?: string;
  targetRacePriority?: "P1" | "P2" | "P3"; 
  targetRaceDate?: string;
  targetRaceDistanceKm?: number;
  // Regra de Ouro: Matriz de 16 Semanas (Valores de 1 a 16)
  currentWeek?: number;
  hrv?: number;
  painLevel?: number;
  races?: Race[];
}

export interface WorkoutPayload {
  date: string;
  // Regra de Ouro: Quilometragem sempre inteira
  distanceKm: number; 
  type: string;
  durationMin: number;
  week: number;
  // Regra de Ouro: Análise Quali/Quanti e Prevenção de Lesões
  rpe: number;         // Rate of Perceived Exertion (1-10)
  painLevel?: number;  // Radar Articular (1-10)
  injuryAlert?: string; // Descrição de dores (ex: "Ombro Direito")
}

export interface SpotifyPlaylist {
  id: string;
  name: string;
  description: string;
  imageUrl: string | null;
  tracksTotal: number;
  spotifyUrl: string;
  spotifyUri: string;
  owner: string;
}

// -----------------------------------------------------------------------------
// MÓDULOS DA API (SERVIÇOS DE TELEMETRIA)
// -----------------------------------------------------------------------------

export const ProCoachAPI = {
  // --- SINCRONIZAÇÃO E MATRIZ DE 16 SEMANAS ---
  async syncAthlete(payload: AthletePayload) {
    // Garante que a semana nunca fuja do ciclo de 16 semanas
    if (payload.currentWeek && (payload.currentWeek < 1 || payload.currentWeek > 16)) {
      console.warn("[RADAR] Semana fora da Matriz. Ajustando para limites da base.");
      payload.currentWeek = Math.max(1, Math.min(16, payload.currentWeek));
    }
    
    return request<{ athlete: unknown }>("/procoach/athletes/sync", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },

  async getAthlete(deviceId: string) {
    return request<{ athlete: unknown }>(`/procoach/athletes/${deviceId}`);
  },

  // --- TELEMETRIA TÁTICA (TREINOS) ---
  async logWorkout(deviceId: string, payload: WorkoutPayload) {
    // REGRA DE OURO: QUILOMETRAGEM REDONDA
    // Intercepta e arredonda matematicamente antes de enviar ao Render
    const cargaBlindada = {
      ...payload,
      distanceKm: Math.round(payload.distanceKm)
    };

    return request<{ entry: unknown }>(
      `/procoach/athletes/${deviceId}/workouts`,
      { method: "POST", body: JSON.stringify(cargaBlindada) }
    );
  },

  async logWorkoutFeedback(deviceId: string, payload: { date: string; rpe?: number; painLevel?: number; notes?: string }) {
    return request<{ ok: boolean; entryDate: string }>(`/procoach/athletes/${deviceId}/workout-feedback`, {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },

  async getWorkouts(deviceId: string, limit = 30) {
    return request<{ entries: unknown[] }>(
      `/procoach/athletes/${deviceId}/workouts?limit=${limit}`
    );
  },

  async getWeeklyStats(deviceId: string) {
    return request<{ weeklyCompleted: Record<number, number> }>(
      `/procoach/athletes/${deviceId}/weekly-stats`
    );
  },

  // --- ESTOQUE DE GÉIS ---
  async getGelStock(deviceId: string) {
    return request<{ gelsInStock: number }>(`/procoach/athletes/${deviceId}/gel-stock`);
  },

  async setGelStock(deviceId: string, gelsInStock: number) {
    return request<{ gelsInStock: number }>(`/procoach/athletes/${deviceId}/gel-stock`, {
      method: "PUT",
      body: JSON.stringify({ gelsInStock }),
    });
  },

  async logGelUsage(deviceId: string, payload: { date: string; context: string; gelsUsed: number }) {
    return request<{ gelsInStock: number; gelsUsed: number; entryDate: string; context: string }>(
      `/procoach/athletes/${deviceId}/gel-usage`,
      { method: "POST", body: JSON.stringify(payload) }
    );
  },

  async importPlanJson(deviceId: string, payload: unknown) {
    return request<{ imported: number; firstDate: string; lastDate: string }>(
      `/procoach/athletes/${deviceId}/plan/import-json`,
      { method: "POST", body: JSON.stringify(payload) }
    );
  },

  async getPlan(deviceId: string, opts: { from?: string; to?: string } = {}) {
    const qs = new URLSearchParams();
    if (opts.from) qs.set("from", opts.from);
    if (opts.to) qs.set("to", opts.to);
    const suffix = qs.toString() ? `?${qs.toString()}` : "";
    return request<{
      sessions: Array<{
        session_date: string;
        day_name: string | null;
        activity: string;
        pace_target: string | null;
        treadmill_speed: string | null;
        rest_interval: string | null;
        structure: string | null;
        planned_km?: number;
      }>;
    }>(`/procoach/athletes/${deviceId}/plan${suffix}`);
  },

  async getPlanToday(deviceId: string, date?: string) {
    const suffix = date ? `?date=${encodeURIComponent(date)}` : "";
    return request<{
      session: null | {
        session_date: string;
        day_name: string | null;
        activity: string;
        pace_target: string | null;
        treadmill_speed: string | null;
        rest_interval: string | null;
        structure: string | null;
        planned_km?: number;
      };
    }>(`/procoach/athletes/${deviceId}/plan/today${suffix}`);
  },

  async getCompliance(deviceId: string, opts: { from?: string; to?: string } = {}) {
    const qs = new URLSearchParams();
    if (opts.from) qs.set("from", opts.from);
    if (opts.to) qs.set("to", opts.to);
    const suffix = qs.toString() ? `?${qs.toString()}` : "";
    return request<{
      from: string;
      to: string;
      plannedSessions: number;
      plannedKm: number;
      completedSessions: number;
      completedKm: number;
    }>(`/procoach/athletes/${deviceId}/compliance${suffix}`);
  },

  async upsertBioimpedance(deviceId: string, payload: unknown) {
    return request<{ entry: Record<string, unknown> | null }>(`/procoach/athletes/${deviceId}/bioimpedance`, {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },

  async getBioimpedance(deviceId: string, limit = 30) {
    return request<{ entries: Array<Record<string, unknown>> }>(
      `/procoach/athletes/${deviceId}/bioimpedance?limit=${Math.max(1, Math.min(90, limit))}`
    );
  },

  // --- AUTENTICAÇÃO ---
  async sendOTP(phone: string) {
    return request<{ sent: boolean; phone: string }>("/auth/otp/send", {
      method: "POST",
      body: JSON.stringify({ phone }),
    });
  },

  async verifyOTP(phone: string, code: string, deviceId: string) {
    return request<{ token: string; athlete: unknown; expiresAt: string }>(
      "/auth/otp/verify",
      {
        method: "POST",
        body: JSON.stringify({ phone, code, deviceId }),
      }
    );
  },

  async verifyToken(token: string) {
    return request<{ valid: boolean; athlete: unknown }>("/auth/verify-token", {
      method: "POST",
      body: JSON.stringify({ token }),
    });
  },

  async logout(token: string) {
    return request<{ success: boolean }>("/auth/logout", {
      method: "POST",
      body: JSON.stringify({ token }),
    });
  },

  // --- INTEGRAÇÃO STRAVA ---
  async stravaStatus(deviceId: string) {
    return request<{ connected: boolean; configured: boolean; lastSyncAt: string | null }>(
      `/strava/status-device?deviceId=${encodeURIComponent(deviceId)}`
    );
  },

  async stravaSync(deviceId: string) {
    return request<{ imported: number; synced: boolean }>("/strava/sync-device", {
      method: "POST",
      body: JSON.stringify({ deviceId }),
    });
  },

  async stravaDisconnect(deviceId: string) {
    return request<{ disconnected: boolean }>("/strava/disconnect-device", {
      method: "POST",
      body: JSON.stringify({ deviceId }),
    });
  },

  async stravaConnectUrl(deviceId: string): Promise<string> {
    const res = await request<{ url: string }> (
      `/strava/connect-url?deviceId=${encodeURIComponent(deviceId)}`
    );
    return res.url;
  },

  // --- NOTIFICAÇÕES TÁTICAS ---
  async registerPushToken(deviceId: string, pushToken: string) {
    return request<{ registered: boolean }>(
      `/procoach/athletes/${deviceId}/push-token`,
      { method: "POST", body: JSON.stringify({ token: pushToken }) }
    );
  },

  // --- ORÁCULO DE IA E LOGÍSTICA ---
  async generateAIWorkout(payload: {
    deviceId: string;
    currentWeek: number;
    hrv: number;
    painLevel: number;
    targetRaceDistanceKm: number;
    targetRaceDate: string;
  }) {
    return request<{
      workout: {
        type: string;
        distanceKm: number;
        durationMin: number;
        description: string;
        reasoning: string;
      };
    }>("/procoach/ai-workout", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },

  async getSpotifyPlaylist(workoutType: string) {
    return request<{ playlist: SpotifyPlaylist; workoutLabel: string }>(
      `/spotify/playlist-for-workout?workoutType=${encodeURIComponent(workoutType)}`
    );
  },

  async generatePostRaceRecovery(payload: {
    deviceId: string;
    raceName: string;
    raceDistanceKm: number;
    finishDurationSec: number;
    currentWeek: number;
  }) {
    return request<{
      totalDays: number;
      recoveryDays: Array<{
        dayOffset: number;
        type: string;
        distanceKm: number;
        durationMin: number;
        description: string;
      }>;
    }>("/procoach/post-race-recovery", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  },
};
