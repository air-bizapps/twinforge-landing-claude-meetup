#!/usr/bin/env node
// Gate de contraste WCAG 2.1 AA para a landing.
//
// Le os tokens direto do index.html e checa cada par texto/fundo que a pagina
// realmente produz — incluindo estados como :hover, onde o fundo do card muda
// e leva o texto junto. Sai com codigo 1 se algum par reprovar.
//
//   node scripts/check-contrast.mjs

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const html = readFileSync(resolve(root, "index.html"), "utf8");

/** Le `--nome:#RRGGBB` do bloco :root. */
function token(name) {
  const match = html.match(new RegExp(`--${name}\\s*:\\s*(#[0-9A-Fa-f]{6})`));
  if (!match) throw new Error(`token --${name} nao encontrado em index.html`);
  return match[1].toUpperCase();
}

function channel(value) {
  const c = value / 255;
  return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
}

function luminance(hex) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
}

function ratio(fg, bg) {
  const [hi, lo] = [luminance(fg), luminance(bg)].sort((a, b) => b - a);
  return (hi + 0.05) / (lo + 0.05);
}

// Pares que a pagina realmente renderiza. O estado :hover conta: o fundo do
// card vira --panel-2 e o texto dentro dele vai junto.
const PAIRS = [
  { el: ".label", fg: "dim", bg: "ink" },
  { el: ".eventbar__in", fg: "dim", bg: "ink" },
  { el: ".brand__tag", fg: "dim", bg: "ink" },
  { el: ".note", fg: "dim", bg: "ink" },
  { el: ".foot__c", fg: "dim", bg: "ink" },
  { el: ".verdict__quote cite", fg: "dim", bg: "ink" },
  { el: ".card__link", fg: "dim", bg: "panel" },
  { el: ".card__link (:hover)", fg: "dim", bg: "panel-2" },
  { el: ".verdict__who", fg: "dim", bg: "panel" },
  { el: ".verdict__say", fg: "dim", bg: "panel" },
  { el: ".verdict__foot", fg: "dim", bg: "panel" },
  { el: ".verdict__foot (col--gate)", fg: "dim", bg: "panel-2" },
  { el: ".verdict__code .prompt", fg: "dim", bg: "panel" },
  // Rotulos do diagrama de arquitetura (.d-k). Herdam --dim via fill.
  // Os que ficam sobre o fundo do .arch__diagram (--panel) e os que
  // caem dentro de um .d-box (--panel-2).
  { el: ".d-k (fundo diagrama)", fg: "dim", bg: "panel" },
  { el: ".d-k (dentro do d-box)", fg: "dim", bg: "panel-2" },
  { el: "corpo", fg: "text", bg: "ink" },
  { el: "secundario", fg: "mute", bg: "ink" },
  { el: "secundario em card", fg: "mute", bg: "panel" },
];

const MIN = 4.5; // WCAG 2.1 AA, texto normal

let failures = 0;
const rows = PAIRS.map((pair) => {
  const fg = token(pair.fg);
  const bg = token(pair.bg);
  const value = ratio(fg, bg);
  const pass = value >= MIN;
  if (!pass) failures += 1;
  return { ...pair, fg, bg, value, pass };
});

const width = Math.max(...rows.map((r) => r.el.length));
console.log(`Gate de contraste WCAG AA (minimo ${MIN.toFixed(1)}:1)\n`);
for (const row of rows) {
  const label = row.el.padEnd(width);
  const value = `${row.value.toFixed(2)}:1`.padStart(7);
  console.log(
    `${row.pass ? "PASS" : "FAIL"}  ${label}  ${row.fg} sobre ${row.bg}  ${value}`,
  );
}

console.log(
  `\n${rows.length - failures}/${rows.length} pares passam. ` +
    (failures === 0 ? "Gate verde." : `${failures} reprovando.`),
);
process.exit(failures === 0 ? 0 : 1);
