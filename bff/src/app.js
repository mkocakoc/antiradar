import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

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
    allowedHeaders: ['Content-Type', 'Authorization'],
    optionsSuccessStatus: 204,
    credentials: false,
    maxAge: 86400,
  }),
);

app.use(express.json({ limit: '1mb' }));

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
