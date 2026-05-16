import { 
  pgTable, 
  serial, 
  integer, 
  varchar, 
  timestamp, 
  real 
} from 'drizzle-orm/pg-core';

// Referência fictícia à tabela de atletas caso ela já exista
// import { athletes } from './athletes'; 

export const shoes = pgTable('procoach_shoes', {
  id: serial('id').primaryKey(),
  
  // No Postgres, FKs geralmente apontam para id integer.
  // Ajuste para varchar/text se o seu athlete_id for string (ex: UUID).
  athleteId: integer('athlete_id').notNull(), 
  
  nickname: varchar('nickname', { length: 120 }).notNull(),
  brand: varchar('brand', { length: 80 }),
  model: varchar('model', { length: 120 }),
  startDate: varchar('start_date', { length: 32 }), // Formato YYYY-MM-DD
  
  // Uso 'real' (float) pois no app Flutter tratamos como 'double'
  initialKm: real('initial_km').notNull().default(0),
  currentKm: real('current_km').notNull().default(0), // Coluna para a soma atômica
  targetKm: real('target_km').notNull().default(500),
  
  // retiredAt nulo indica que o tênis está ATIVO
  retiredAt: timestamp('retired_at', { withTimezone: true }),
  
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow(),
});