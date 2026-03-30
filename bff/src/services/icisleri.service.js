import { Agent, request } from 'undici';

import { env } from '../config/env.js';
import { AppError } from '../errors.js';

const upstreamAgent = new Agent({
  keepAliveTimeout: 10_000,
  keepAliveMaxTimeout: 30_000,
  connections: 50,
});

const upstreamUrl = new URL(env.upstreamUrl);
const upstreamBasePath = upstreamUrl.pathname.replace(/\/CreateRoute$/i, '');

const endpoint = (path, query = '') => {
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  const suffix = query ? `?${query}` : '';
  return new URL(`${upstreamBasePath}${normalizedPath}${suffix}`, upstreamUrl.origin).toString();
};

const CITIES_ENDPOINT = endpoint('/GetCities');
const DISTRICTS_ENDPOINT = (cityId) => endpoint('/GetDistricts', `cityId=${encodeURIComponent(cityId)}`);

const normalizeTr = (value) =>
  String(value ?? '')
    .trim()
    .toLocaleLowerCase('tr-TR')
    .replaceAll('ı', 'i')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ş', 's')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c')
    .replace(/\s+/g, ' ');

let citiesCache = {
  expiresAt: 0,
  value: null,
};

const districtsCache = new Map();

const cacheTtlMs = 30 * 60 * 1000;

const requestText = async (url, options) => {
  let response;

  try {
    response = await request(url, {
      ...options,
      dispatcher: upstreamAgent,
      bodyTimeout: env.upstreamTimeoutMs,
      headersTimeout: env.upstreamTimeoutMs,
    });
  } catch (error) {
    throw new AppError('İçişleri servisine erişilemedi.', {
      statusCode: 502,
      code: 'UPSTREAM_UNREACHABLE',
      details: error.message,
    });
  }

  const text = await response.body.text();

  if (response.statusCode >= 500) {
    throw new AppError('İçişleri servisi geçici olarak hata veriyor.', {
      statusCode: 502,
      code: 'UPSTREAM_500',
      details: `status=${response.statusCode}`,
    });
  }

  if (response.statusCode >= 300) {
    throw new AppError('İçişleri servisi isteği yönlendirdi/engelledi.', {
      statusCode: 502,
      code: 'UPSTREAM_REDIRECTED',
      details: `status=${response.statusCode}${response.headers?.location ? `, location=${response.headers.location}` : ''}`,
    });
  }

  if (response.statusCode >= 400) {
    throw new AppError('İçişleri servisi isteği reddetti.', {
      statusCode: 502,
      code: 'UPSTREAM_4XX',
      details: `status=${response.statusCode}`,
    });
  }

  return {
    text,
    headers: response.headers,
    statusCode: response.statusCode,
  };
};

const requestJson = async (url, options) => {
  const { text, headers, statusCode } = await requestText(url, options);

  try {
    return JSON.parse(text);
  } catch (_error) {
    throw new AppError('İçişleri servisinden JSON yerine farklı içerik alındı.', {
      statusCode: 502,
      code: 'UPSTREAM_INVALID_JSON',
      details: `status=${statusCode}, contentType=${headers?.['content-type'] ?? 'unknown'}, bodyExcerpt=${text.slice(0, 200).replace(/\s+/g, ' ').trim()}`,
    });
  }
};

const getCities = async () => {
  const now = Date.now();
  if (citiesCache.value && citiesCache.expiresAt > now) {
    return citiesCache.value;
  }

  const cities = await requestJson(CITIES_ENDPOINT, {
    method: 'GET',
    headers: {
      accept: 'application/json, text/plain, */*',
      'x-requested-with': 'XMLHttpRequest',
    },
  });

  if (!Array.isArray(cities)) {
    throw new AppError('İçişleri şehir listesi beklenen formatta değil.', {
      statusCode: 502,
      code: 'UPSTREAM_INVALID_CITIES',
    });
  }

  citiesCache = {
    value: cities,
    expiresAt: now + cacheTtlMs,
  };

  return cities;
};

const getDistrictsByCityId = async (cityId) => {
  const key = String(cityId);
  const now = Date.now();
  const cached = districtsCache.get(key);

  if (cached && cached.expiresAt > now) {
    return cached.value;
  }

  const districts = await requestJson(DISTRICTS_ENDPOINT(key), {
    method: 'GET',
    headers: {
      accept: 'application/json, text/plain, */*',
      'x-requested-with': 'XMLHttpRequest',
    },
  });

  if (!Array.isArray(districts)) {
    throw new AppError('İçişleri ilçe listesi beklenen formatta değil.', {
      statusCode: 502,
      code: 'UPSTREAM_INVALID_DISTRICTS',
      details: `cityId=${key}`,
    });
  }

  districtsCache.set(key, {
    value: districts,
    expiresAt: now + cacheTtlMs,
  });

  return districts;
};

export const fetchCitiesFromIcisleri = async () => {
  const cities = await getCities();
  return cities.map((item) => ({
    id: Number(item.Id),
    name: String(item.Name),
  }));
};

export const fetchDistrictsFromIcisleri = async ({ cityId }) => {
  const districts = await getDistrictsByCityId(cityId);
  return districts.map((item) => ({
    id: Number(item.Id),
    name: String(item.Name),
    latitude: Number(item.Latitude),
    longitude: Number(item.Longitude),
  }));
};

const splitCityDistrict = (rawInput) => {
  const raw = String(rawInput ?? '').trim();
  if (!raw) return { cityHint: null, districtHint: null };

  const parts = raw.split(',').map((part) => part.trim()).filter(Boolean);
  if (parts.length >= 2) {
    return {
      cityHint: parts[0],
      districtHint: parts.slice(1).join(', '),
    };
  }

  return {
    cityHint: null,
    districtHint: raw,
  };
};

const findCityByName = (cities, input) => {
  const needle = normalizeTr(input);
  if (!needle) return null;
  return cities.find((city) => normalizeTr(city?.Name) === needle) ?? null;
};

const findDistrictInCity = (districts, input) => {
  const needle = normalizeTr(input);
  if (!needle) return null;
  return districts.find((district) => normalizeTr(district?.Name) === needle) ?? null;
};

const pickDefaultDistrictForCity = (city, districts) => {
  if (!Array.isArray(districts) || districts.length === 0) {
    return null;
  }

  const exactByCityName = findDistrictInCity(districts, city?.Name);
  if (exactByCityName) {
    return exactByCityName;
  }

  return districts[0];
};

const resolveDistrictSelection = async (input, cities) => {
  const { cityHint, districtHint } = splitCityDistrict(input);

  if (cityHint && districtHint) {
    const city = findCityByName(cities, cityHint);
    if (!city) {
      throw new AppError('Girilen başlangıç/varış ili bulunamadı.', {
        statusCode: 400,
        code: 'CITY_NOT_FOUND',
        details: cityHint,
      });
    }

    const districts = await getDistrictsByCityId(city.Id);
    const district = findDistrictInCity(districts, districtHint);

    if (!district) {
      throw new AppError('Girilen başlangıç/varış ilçesi belirtilen ilde bulunamadı.', {
        statusCode: 400,
        code: 'DISTRICT_NOT_FOUND_IN_CITY',
        details: `${city.Name} -> ${districtHint}`,
      });
    }

    return { city, district };
  }

  const districtNeedle = normalizeTr(districtHint);
  const districtMatches = [];

  for (const city of cities) {
    const districts = await getDistrictsByCityId(city.Id);
    const district = districts.find((item) => normalizeTr(item?.Name) === districtNeedle);
    if (district) {
      districtMatches.push({ city, district });
      if (districtMatches.length > 1) {
        break;
      }
    }
  }

  if (districtMatches.length === 1) {
    return districtMatches[0];
  }

  if (districtMatches.length > 1) {
    throw new AppError('İlçe adı birden fazla ilde bulundu. Lütfen "İl, İlçe" formatında girin.', {
      statusCode: 400,
      code: 'DISTRICT_AMBIGUOUS',
      details: districtHint,
    });
  }

  const matchedCity = findCityByName(cities, districtHint);
  if (matchedCity) {
    const districts = await getDistrictsByCityId(matchedCity.Id);
    const fallbackDistrict = pickDefaultDistrictForCity(matchedCity, districts);

    if (!fallbackDistrict) {
      throw new AppError('Seçilen il için ilçe listesi alınamadı.', {
        statusCode: 400,
        code: 'CITY_HAS_NO_DISTRICT',
        details: matchedCity.Name,
      });
    }

    return {
      city: matchedCity,
      district: fallbackDistrict,
      fallbackByCity: true,
    };
  }

  throw new AppError('İlçe/il bilgisi bulunamadı. Lütfen "İlçe" veya "İl, İlçe" formatında girin.', {
    statusCode: 400,
    code: 'DISTRICT_NOT_FOUND',
    details: districtHint,
  });
};

export const fetchRouteFromIcisleri = async ({ fromDistrict, toDistrict }) => {
  const cities = await getCities();

  const fromSelection = await resolveDistrictSelection(fromDistrict, cities);
  const toSelection = await resolveDistrictSelection(toDistrict, cities);

  const formBody = new URLSearchParams({
    fromLatitude: String(fromSelection.district.Latitude),
    fromLongitude: String(fromSelection.district.Longitude),
    toLatitude: String(toSelection.district.Latitude),
    toLongitude: String(toSelection.district.Longitude),
    fromDistrictId: String(fromSelection.district.Id),
    toDistrictId: String(toSelection.district.Id),
  }).toString();

  const result = await requestJson(env.upstreamUrl, {
    method: 'POST',
    headers: {
      'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
      accept: 'application/json, text/plain, */*',
      'x-requested-with': 'XMLHttpRequest',
    },
    body: formBody,
  });

  if (fromSelection.fallbackByCity || toSelection.fallbackByCity) {
    return {
      ...result,
      fallback: {
        from: fromSelection.fallbackByCity
          ? `${fromSelection.city.Name}, ${fromSelection.district.Name}`
          : null,
        to: toSelection.fallbackByCity ? `${toSelection.city.Name}, ${toSelection.district.Name}` : null,
      },
    };
  }

  return result;
};
