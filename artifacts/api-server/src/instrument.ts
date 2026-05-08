import * as Sentry from "@sentry/node";

function parseOptionalNumber(value: string | undefined): number | undefined {
  if (!value) return undefined;
  const n = Number(value);
  if (!Number.isFinite(n)) return undefined;
  return n;
}

export function initSentry() {
  const dsn = process.env.SENTRY_DSN;
  if (!dsn) return;

  Sentry.init({
    dsn,
    environment: process.env.SENTRY_ENVIRONMENT ?? process.env.NODE_ENV,
    release: process.env.SENTRY_RELEASE ?? process.env.RENDER_GIT_COMMIT,
    tracesSampleRate: parseOptionalNumber(process.env.SENTRY_TRACES_SAMPLE_RATE),
    beforeSend(event) {
      const headers = event.request?.headers;
      if (!headers || typeof headers !== "object") return event;

      for (const key of ["authorization", "cookie", "set-cookie"]) {
        delete (headers as Record<string, unknown>)[key];
        delete (headers as Record<string, unknown>)[key.toUpperCase()];
      }

      return event;
    },
  });
}

