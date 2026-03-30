import dotenv from 'dotenv';

dotenv.config();

const parseCsv = (value) =>
  value
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

export const env = {
  port: Number(process.env.PORT ?? 3000),
  corsOrigins: process.env.CORS_ORIGINS ? parseCsv(process.env.CORS_ORIGINS) : ['*'],
  upstreamUrl:
    process.env.ICISLERI_ROUTE_URL ??
    'https://www.icisleri.gov.tr/ISAYWebPart/PolGenControlPointV2/CreateRoute',
  upstreamTimeoutMs: Number(process.env.UPSTREAM_TIMEOUT_MS ?? 7000),
};
