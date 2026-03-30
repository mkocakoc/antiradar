import { AppError, buildEmptyState } from '../errors.js';

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
