import { AppError, buildEmptyState } from '../errors.js';
import { emitLog } from '../logger.js';

export const notFoundHandler = (_req, res) => {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: 'Endpoint bulunamadı.',
    },
    data: buildEmptyState(),
  });
};

export const errorHandler = (error, _req, res, _next) => {
  if (_req?.path === '/api/route' || _req?.originalUrl === '/api/route') {
    emitLog({
      level: 'error',
      eventName: 'route_request_completed',
      requestId: _req.requestId,
      durationMs: Date.now() - (_req.requestStartedAt ?? Date.now()),
      resultType: 'error',
      fromDistrict: _req.routeTelemetry?.fromDistrict ?? null,
      toDistrict: _req.routeTelemetry?.toDistrict ?? null,
      radarCount: 0,
      speedTunnelCount: 0,
      errorCode: error?.code ?? 'INTERNAL_ERROR',
    });
  }

  const appError =
    error instanceof AppError
      ? error
      : new AppError('Beklenmeyen bir hata oluştu.', {
          statusCode: 500,
          code: 'INTERNAL_ERROR',
        });

  res.status(appError.statusCode).json({
    success: false,
    error: {
      code: appError.code,
      message: appError.message,
      details: appError.details,
    },
    data: buildEmptyState(),
  });
};
