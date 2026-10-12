const assert = require('node:assert/strict');
const {cycleAt} = require('../web/overlay.js');
for (const t of [7,23.99,24,24.5,48,300]) {
 assert.deepEqual(cycleAt(t),{outline:1,color:1,settled:1,fade:1},`Startup reveal must stay complete at ${t}s`);
}
console.log('PASS REG-001: reveal completes once and stays visible beyond previous loop boundaries');
