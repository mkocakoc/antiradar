import { Router } from 'express';

import { AppError, buildEmptyState } from '../errors.js';
import {
  fetchCitiesFromIcisleri,
  fetchDistrictsFromIcisleri,
  fetchRouteFromIcisleri,
} from '../services/icisleri.service.js';
import { transformRouteResponse } from '../transformers/route-transformer.js';
import { emitLog } from '../logger.js';

const routeRouter = Router();

const logRouteTelemetry = ({
  requestId,
  durationMs,
  resultType,
  fromDistrict,
  toDistrict,
  radarCount,
  speedTunnelCount,
  errorCode,
}) => {
  emitLog({
    eventName: 'route_request_completed',
    requestId,
    durationMs,
    resultType,
    fromDistrict,
    toDistrict,
    radarCount,
    speedTunnelCount,
    errorCode,
  });
};

routeRouter.get('/cities', async (_req, res, next) => {
  try {
    const cities = await fetchCitiesFromIcisleri();
    return res.status(200).json({
      success: true,
      data: cities,
    });
  } catch (error) {
    return next(error);
  }
});

routeRouter.get('/districts', async (req, res, next) => {
  const cityId = String(req.query?.cityId ?? '').trim();

  if (!cityId) {
    return next(
      new AppError('cityId alanı zorunludur.', {
        statusCode: 400,
        code: 'VALIDATION_ERROR',
      }),
    );
  }

  try {
    const districts = await fetchDistrictsFromIcisleri({ cityId });
    return res.status(200).json({
      success: true,
      data: districts,
    });
  } catch (error) {
    return next(error);
  }
});

routeRouter.post('/route', async (req, res, next) => {
  const fromDistrict = String(req.body?.fromDistrict ?? '').trim();
  const toDistrict = String(req.body?.toDistrict ?? '').trim();
  req.routeTelemetry = { fromDistrict, toDistrict };

  if (!fromDistrict || !toDistrict) {
    return next(
      new AppError('fromDistrict ve toDistrict alanları zorunludur.', {
        statusCode: 400,
        code: 'VALIDATION_ERROR',
      }),
    );
  }

  try {
    const rawResponse = await fetchRouteFromIcisleri({
      fromDistrict,
      toDistrict,
    });

    const transformed = transformRouteResponse(rawResponse);

    if (!transformed.speedTunnels.length && !transformed.radars.length) {
      logRouteTelemetry({
        requestId: req.requestId,
        durationMs: Date.now() - (req.requestStartedAt ?? Date.now()),
        resultType: 'empty',
        fromDistrict,
        toDistrict,
        radarCount: 0,
        speedTunnelCount: 0,
        errorCode: 'EMPTY_DATA',
      });

      return res.status(200).json({
        success: false,
        error: {
          code: 'EMPTY_DATA',
          message: 'Seçilen güzergah için radar veya hız tüneli verisi bulunamadı.',
          details: {
            fromDistrict,
            toDistrict,
          },
        },
        data: buildEmptyState(),
      });
    }

    logRouteTelemetry({
      requestId: req.requestId,
      durationMs: Date.now() - (req.requestStartedAt ?? Date.now()),
      resultType: 'success',
      fromDistrict,
      toDistrict,
      radarCount: transformed.summary?.radarCount ?? transformed.radars.length,
      speedTunnelCount:
        transformed.summary?.speedTunnelCount ?? transformed.speedTunnels.length,
      errorCode: null,
    });

    return res.status(200).json({
      success: true,
      message: 'Güzergah verisi başarıyla alındı.',
      data: transformed,
    });
  } catch (error) {
    return next(error);
  }
});

export { routeRouter };
