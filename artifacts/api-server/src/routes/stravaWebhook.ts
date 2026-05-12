import { Router, Request, Response } from 'express';

export const stravaWebhookRouter = Router();

// O token que você vai usar ao se inscrever na API do Strava.
// Adicione isso ao seu arquivo .env no api-server
const VERIFY_TOKEN = process.env.STRAVA_VERIFY_TOKEN || 'STRAVA_COACH_PRO_TOKEN';

/**
 * 1. Endpoint de Validação do Webhook (GET)
 * Exigido pelo Strava para confirmar a assinatura do webhook.
 */
stravaWebhookRouter.get('/webhook/strava', (req: Request, res: Response) => {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  if (mode && token) {
    // Verifica se o modo e o token correspondem aos nossos
    if (mode === 'subscribe' && token === VERIFY_TOKEN) {
      console.log('STRAVA WEBHOOK_VERIFIED');
      res.json({ 'hub.challenge': challenge });
    } else {
      // Responde com '403 Forbidden' se os tokens não baterem
      res.sendStatus(403);
    }
  } else {
    res.sendStatus(400);
  }
});

/**
 * 2. Endpoint de Recebimento de Eventos (POST)
 * Onde o Strava vai enviar as atualizações das atividades dos atletas.
 */
stravaWebhookRouter.post('/webhook/strava', (req: Request, res: Response) => {
  console.log('Strava webhook event received!', req.body);
  
  // O Strava exige que você responda com 200 OK IMEDIATAMENTE (em até 2s).
  // Processe a requisição de forma assíncrona abaixo desta linha (ou use filas/workers).
  res.status(200).send('EVENT_RECEIVED');
  
  const { object_type, aspect_type, object_id, owner_id, updates } = req.body;
  
  // TODO: Adicionar lógica para salvar a atividade no banco de dados e notificar a IA
  if (object_type === 'activity' && aspect_type === 'create') {
    // syncActivityData(owner_id, object_id);
  }
});