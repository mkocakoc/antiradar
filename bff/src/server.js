import { app } from './app.js';
import { env } from './config/env.js';
import { emitLog } from './logger.js';

app.listen(env.port, () => {
  emitLog({
    eventName: 'server_started',
    port: env.port,
  });
});
