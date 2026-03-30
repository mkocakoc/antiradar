import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { randomUUID } from 'crypto';

import { env } from './config/env.js';
import { routeRouter } from './routes/route.js';
import { errorHandler, notFoundHandler } from './middleware/error-handler.js';

const app = express();

app.disable('x-powered-by');
app.use(helmet());

app.use(
  cors({
    origin(origin, callback) {
      if (!origin || env.corsOrigins.includes('*') || env.corsOrigins.includes(origin)) {
        return callback(null, true);
      }

      return callback(new Error('Origin not allowed by CORS policy'));
    },
    methods: ['POST', 'GET', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-Id'],
    optionsSuccessStatus: 204,
    credentials: false,
    maxAge: 86400,
  }),
);

app.use(express.json({ limit: '1mb' }));

app.use((req, res, next) => {
  const incomingRequestId = req.headers['x-request-id'];
  const requestId =
    typeof incomingRequestId === 'string' && incomingRequestId.trim().length > 0
      ? incomingRequestId.trim()
      : randomUUID();

  req.requestId = requestId;
  req.requestStartedAt = Date.now();
  res.setHeader('x-request-id', requestId);
  next();
});

app.get('/health', (_req, res) => {
  res.status(200).json({
    success: true,
    message: 'BFF is healthy',
    timestamp: new Date().toISOString(),
  });
});

app.use('/api', routeRouter);

app.use(notFoundHandler);
app.use(errorHandler);

export { app };
