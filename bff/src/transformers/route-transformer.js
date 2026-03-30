const toNumber = (value) => {
  if (typeof value === 'number') {
    return Number.isFinite(value) ? value : null;
  }

  if (typeof value === 'string') {
    const normalized = value.replace(',', '.').trim();
    const parsed = Number.parseFloat(normalized);
    return Number.isFinite(parsed) ? parsed : null;
  }

  return null;
};

const normalizeCoordinate = (point) => {
  if (!point || typeof point !== 'object') {
    return null;
  }

  const x = toNumber(point.x ?? point.X ?? point.lng ?? point.longitude);
  const y = toNumber(point.y ?? point.Y ?? point.lat ?? point.latitude);

  if (x === null || y === null) {
    return null;
  }

  return {
    lat: y,
    lng: x,
  };
};

const normalizeCoordinates = (coordinates) => {
  if (!Array.isArray(coordinates)) {
    return [];
  }

  return coordinates.map(normalizeCoordinate).filter(Boolean);
};

const pickArray = (...candidates) => candidates.find((item) => Array.isArray(item)) ?? [];

const mapControlPoint = (item, type) => {
  const path = normalizeCoordinates(
    item?.coordinates ?? item?.Coordinates ?? item?.path ?? item?.Path ?? [],
  );

  return {
    id: String(item?.id ?? item?.Id ?? item?.ControlPointId ?? `${type}-unknown`),
    type,
    label: item?.name ?? item?.Name ?? item?.label ?? null,
    district: item?.district ?? item?.District ?? null,
    road: item?.road ?? item?.Road ?? item?.roadName ?? item?.RoadName ?? null,
    path,
    pathPointCount: path.length,
  };
};

export const transformRouteResponse = (raw) => {
  const speedTunnelsRaw = pickArray(raw?.SpeedTunnels, raw?.speedTunnels, raw?.data?.SpeedTunnels);
  const radarsRaw = pickArray(raw?.Radars, raw?.radars, raw?.data?.Radars);

  const speedTunnels = speedTunnelsRaw
    .map((item) => mapControlPoint(item, 'speed_tunnel'))
    .filter((item) => item.pathPointCount > 0);

  const radars = radarsRaw
    .map((item) => mapControlPoint(item, 'radar'))
    .filter((item) => item.pathPointCount > 0);

  return {
    speedTunnels,
    radars,
    summary: {
      speedTunnelCount: speedTunnels.length,
      radarCount: radars.length,
    },
  };
};
