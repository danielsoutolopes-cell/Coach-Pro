# ProCoach OS — Equipamentos (Tênis) + Atribuição por Treino (Strava/Manual)

Data: 2026-05-09

## Contexto
O app já registra treinos concluídos em `procoach_workout_entries` e sincroniza atividades do Strava para essa mesma tabela. Queremos:

1) Uma área de **Equipamentos (Tênis)** para cadastrar tênis e acompanhar **km acumulado**.
2) O km por tênis deve ser calculado com base em **treinos concluídos** (fonte A).
3) Quando o app detectar **treino novo vindo do Strava**, deve **obrigar** o usuário a escolher o tênis (somente para corridas). Para bike/força, marcar automaticamente “Sem tênis”.
4) Armazenamento **híbrido**: servidor como fonte de verdade + cache local para UX/offline.

## Objetivos
- Registrar e listar tênis por atleta (ativos e arquivados).
- Associar um tênis a um treino concluído (manual e via Strava).
- Calcular e exibir km acumulado por tênis + vida útil alvo + alertas.
- Fluxo obrigatório de seleção de tênis ao importar corridas do Strava.

## Não-objetivos (por enquanto)
- Inferência automática do tênis via Strava.
- Cálculo por “treinos planejados” (cronograma) ou modelos híbridos planejado vs realizado.

## Regras de produto (fechadas)
- Fonte de km: **somente treinos concluídos**.
- Seleção do tênis: **no momento de concluir** (check-in/registro) e **na primeira detecção** de treino novo (Strava).
- Strava: seleção obrigatória para **corrida**. Não-corrida: `Sem tênis` automático.
- UI: layout “C” — Tabs **Ativos | Arquivados**.

---

## Modelo de Dados (Postgres / Drizzle)

### 1) Nova tabela `procoach_shoes`
Armazena os tênis cadastrados por atleta.

Campos:
- `id` (serial, PK)
- `athlete_id` (int, FK → `procoach_athletes.id`, not null)
- `nickname` (varchar(120), not null) — apelido do tênis (ex: “Corre 4”)
- `brand` (varchar(80), null)
- `model` (varchar(120), null)
- `start_date` (varchar(32), null) — formato `YYYY-MM-DD`
- `initial_km` (int, not null, default 0)
- `target_km` (int, not null, default 500) — vida útil alvo
- `retired_at` (timestamptz, null) — null = ativo
- `created_at` (timestamptz, default now)
- `updated_at` (timestamptz, default now)

Índices recomendados:
- `(athlete_id, retired_at)` para listar ativos/arquivados rapidamente.

### 2) Alteração em `procoach_workout_entries`
Adicionar campos:
- `shoe_id` (int, FK → `procoach_shoes.id`, nullable)
- `source` (varchar(16), not null, default `"manual"`) valores: `manual | strava | import_json`
- `external_id` (bigint, nullable) — ex.: `activity.id` do Strava

Observações:
- `shoe_id` é nullable para suportar “Sem tênis / não se aplica”.
- `external_id` permite deduplicação mais robusta no futuro (hoje a dedupe é por `entry_date`).

---

## API (backend)
Base path já existente: `.../api`.

### Shoes
1) `GET /procoach/me/shoes`
Retorno:
```json
{ "shoes": [ /* ativos e arquivados */ ] }
```
Campos mínimos retornados:
- `id, nickname, brand, model, startDate, initialKm, targetKm, retiredAt`
- `kmTotal` (server-computed) e `lastUsedAt` (server-computed) **recomendado**

2) `POST /procoach/me/shoes`
Body:
```json
{ "nickname": "Corre 4", "brand": "Olympikus", "model": "Corre 4", "startDate": "2026-05-01", "initialKm": 0, "targetKm": 500 }
```

3) `PUT /procoach/me/shoes/:id`
Atualiza campos editáveis.

4) `POST /procoach/me/shoes/:id/archive`
Marca `retired_at = now()`. (Opcional: endpoint complementar `/unarchive`.)

### Atribuição do tênis ao treino
5) `POST /procoach/me/workouts/:id/set-shoe`
Body:
```json
{ "shoeId": 123 }
```
Regras:
- valida se `shoeId` pertence ao atleta.
- atualiza `shoe_id` do workout.

### Pendências (corridas Strava sem tênis)
6) `GET /procoach/me/workouts/pending-shoe?limit=20`
Retorna corridas onde:
- `source="strava"`
- `type="corrida"`
- `shoe_id IS NULL`

Retorno:
```json
{ "pending": [ { "id": 1, "entryDate": "2026-05-09", "distanceKm": 5, "durationMin": 32 } ] }
```

### Ajuste no retorno do Strava Sync (recomendado)
7) `POST /strava/sync-device` e `POST /strava/sync` (já existem)
Adicionar retorno opcional:
```json
{ "imported": 3, "pendingShoe": [ /* mesmo shape do endpoint pending */ ] }
```
Isso permite o app disparar o modal imediatamente após sincronizar.

---

## App (ProCoach OS) — Fluxos e UX

### 1) Cache híbrido (server + local)
- `AsyncStorage` guarda cache: `@procoach_shoes_cache_v1`
- Na aba Equipamentos:
  1. Renderiza cache imediatamente.
  2. Faz `GET /procoach/me/shoes` em background.
  3. Atualiza cache + UI.

### 2) Aba “Equipamentos” (Layout C)
Tabs:
- **Ativos**: cards com `kmTotal/targetKm` + barra + último uso + ações.
- **Arquivados**: lista de aposentados, mostrando km final + período de uso.

Card (Ativo):
- Título: `nickname` (e brand/model menor)
- Linha: `kmTotal / targetKm`
- Barra: `kmTotal/targetKm`
- “Último uso”: baseado no treino mais recente com aquele `shoe_id`
- Ações: `Editar`, `Aposentar`

Alertas:
- >= 80%: aviso
- >= 100%: “aposentar recomendado”

### 3) Seleção do tênis ao concluir treino (manual)
No fluxo de “concluir treino” (check-in/registro):
- Campo obrigatório “Tênis usado” quando `type === corrida`.
- Para outros tipos: default “Sem tênis”.

### 4) Seleção obrigatória após Strava Sync
Após `stravaSync()`:
- Se `pendingShoe.length > 0`, abrir um modal em sequência:
  - Exibe treino (data, distância, duração)
  - Lista tênis **Ativos**
  - Ação “+ Adicionar tênis” (cria e volta para selecionar)
  - Botão Confirmar (sem opção “Depois”)
- Para bike/força importados do Strava: servidor já grava `shoe_id = null` e não entra em pendência.

---

## Cálculo de km por tênis
Server-computed (recomendado):
- `kmTotal = initialKm + SUM(distance_km) WHERE shoe_id = X`
- `lastUsedAt = MAX(entry_date) WHERE shoe_id = X`

Vantagens:
- 1 fonte de verdade
- evita drift entre app/dispositivos

---

## Migração e compatibilidade
1) Migração do banco: criar `procoach_shoes` e alterar `procoach_workout_entries`.
2) Backfill:
   - Nenhum backfill obrigatório (treinos antigos ficam `shoe_id null`).
3) Compatibilidade do app:
   - Sem tênis cadastrados: modal força “Adicionar tênis” antes de concluir corridas do Strava.

---

## Observação: Bug crítico “Invalid Date” (Status/Compliance)
Foi identificado que alguns Androids falham ao parsear `new Date(new Date().toLocaleString(...))`, gerando “Invalid Date”.
Correção aplicada no app (aba Status) para calcular datas de São Paulo via `Intl.DateTimeFormat(...).formatToParts()`, garantindo `YYYY-MM-DD` sempre válido.

---

## Plano de testes (alto nível)
- Criar tênis → aparece em Ativos → editar → arquivar → aparece em Arquivados.
- Concluir corrida manual selecionando tênis → kmTotal incrementa.
- Sincronizar Strava com nova corrida → modal obrigatório → após selecionar, treino fica associado e kmTotal incrementa.
- Sincronizar Strava com bike/força → não pede tênis; shoe_id permanece null.
- Reinstalar app (cache vazio) → server repopula tênis e mantém km correto.

