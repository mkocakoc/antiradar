export class AppError extends Error {
  constructor(message, options = {}) {
    super(message);
    this.name = 'AppError';
    this.statusCode = options.statusCode ?? 500;
    this.code = options.code ?? 'INTERNAL_ERROR';
    this.details = options.details ?? null;
  }
}

export const buildEmptyState = () => ({
  speedTunnels: [],
  radars: [],
  controlPoints: [],
  summary: {
    speedTunnelCount: 0,
    radarCount: 0,
    controlPointCount: 0,
  },
});
