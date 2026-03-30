import test from 'node:test';
import assert from 'node:assert/strict';

import { transformRouteResponse } from '../src/transformers/route-transformer.js';

test('transformRouteResponse should parse radars and speed tunnels with numeric coordinates', () => {
  const input = {
    SpeedTunnels: [
      {
        Id: 11,
        Name: 'Tünel A',
        Coordinates: [
          { x: '32.851', y: '39.920' },
          { x: 32.861, y: 39.93 },
        ],
      },
    ],
    Radars: [
      {
        Id: 22,
        Name: 'Radar B',
        coordinates: [{ x: '30.1', y: '40.2' }],
      },
    ],
  };

  const output = transformRouteResponse(input);

  assert.equal(output.summary.speedTunnelCount, 1);
  assert.equal(output.summary.radarCount, 1);
  assert.deepEqual(output.speedTunnels[0].path[0], { lat: 39.92, lng: 32.851 });
  assert.deepEqual(output.radars[0].path[0], { lat: 40.2, lng: 30.1 });
});

test('transformRouteResponse should drop invalid coordinate points', () => {
  const input = {
    Radars: [
      {
        Id: 99,
        coordinates: [
          { x: null, y: null },
          { x: 'abc', y: '39.9' },
        ],
      },
    ],
  };

  const output = transformRouteResponse(input);
  assert.equal(output.summary.radarCount, 0);
  assert.equal(output.radars.length, 0);
});
