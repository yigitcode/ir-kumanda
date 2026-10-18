// Checks the panel's encoders by decoding what they produce.
// Usage: node tools/test_encoders.js assets/panel.html
'use strict';
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');

const html = fs.readFileSync(process.argv[2], 'utf8');
const script = html.match(/<script>([\s\S]*)<\/script>/)[1];
new vm.Script(script, { filename: 'panel.js' }); // full syntax check
const start = script.indexOf('// ---- Encoders');
const end = script.indexOf('// ---- Bridge connection');
const ctx = {};
vm.createContext(ctx);
vm.runInContext(script.slice(start, end) + ';this.api={encodeNec,encodeRc5,parsePronto,toPronto,buildPattern};', ctx);
const { encodeNec, encodeRc5, parsePronto, toPronto, buildPattern } = ctx.api;
const sum = a => a.reduce((s, v) => s + v, 0);

function decodeNec(p) {
  assert.strictEqual(p[0], 9000); assert.strictEqual(p[1], 4500);
  const bytes = [0, 0, 0, 0];
  for (let i = 0; i < 32; i++) {
    assert.strictEqual(p[2 + 2 * i], 562);
    if (p[3 + 2 * i] > 1000) bytes[i >> 3] |= 1 << (i & 7);
  }
  return bytes;
}

function decodeRc5(p) {
  const half = 889;
  const levels = [0]; // leading space that the encoder drops
  p.forEach((d, i) => { if (d < 5000) for (let k = 0; k < Math.round(d / half); k++) levels.push(i % 2 === 0 ? 1 : 0); });
  while (levels.length < 28) levels.push(0);
  const bits = [];
  for (let i = 0; i < 28; i += 2) bits.push(levels[i] === 0 && levels[i + 1] === 1 ? 1 : 0);
  const num = arr => arr.reduce((v, b) => (v << 1) | b, 0);
  return { start: bits[0], field: bits[1], toggle: bits[2], addr: num(bits.slice(3, 8)), cmd: num(bits.slice(8, 14)) };
}

// NEC Toshiba power: 0x40 / 0x12
const nec = encodeNec(0x40, 0x12);
assert.deepStrictEqual(decodeNec(nec.once), [0x40, 0xBF, 0x12, 0xED]);
assert.strictEqual(nec.once.length % 2, 0);
assert.strictEqual(sum(nec.once), 108000);
assert.strictEqual(sum(nec.repeat), 108000);
assert.deepStrictEqual(decodeNec(encodeNec(0x7D02, 0x46).once), [0x02, 0x7D, 0x46, 0xB9]);

// RC5 Vestel power: addr 1 / 0x0C, both toggle states
for (const t of [0, 1]) {
  const rc5 = encodeRc5(0x01, 0x0C, t);
  assert.strictEqual(rc5.once.length % 2, 0);
  assert.strictEqual(sum(rc5.once), 113778);
  assert.deepStrictEqual({ ...decodeRc5(rc5.once) }, { start: 1, field: 1, toggle: t, addr: 1, cmd: 0x0C });
}
for (const cmd of [0x00, 0x35, 0x3F, 0x10]) {
  assert.strictEqual(decodeRc5(encodeRc5(1, cmd, 0).once).cmd, cmd);
}

// Pronto round trip
const pr = toPronto(nec);
const back = parsePronto(pr);
assert.ok(Math.abs(back.freq - 38000) < 400, 'freq ' + back.freq);
assert.strictEqual(back.once.length, nec.once.length);
back.once.forEach((v, i) => assert.ok(Math.abs(v - nec.once[i]) <= 30, `once[${i}] ${v} vs ${nec.once[i]}`));
assert.deepStrictEqual(decodeNec(back.once.map((v, i) => (i < 2 ? [9000, 4500][i] : i % 2 === 0 ? 562 : v))), [0x40, 0xBF, 0x12, 0xED]);

// RC5 Pronto has no separate repeat part
const rc5Pronto = toPronto(encodeRc5(1, 0x0C, 0)).split(' ');
assert.strictEqual(rc5Pronto[3], '0000');
assert.strictEqual(parseInt(rc5Pronto[2], 16) * 2, rc5Pronto.length - 4);

// Repeats: frame + repeat codes
assert.strictEqual(buildPattern(nec, 3).length, nec.once.length + 2 * nec.repeat.length);
console.log('NEC power pronto:', pr.slice(0, 60) + '…');
console.log('RC5 power pronto:', toPronto(encodeRc5(1, 0x0C, 0)));
console.log('OK: tüm kodlayıcı testleri geçti');
