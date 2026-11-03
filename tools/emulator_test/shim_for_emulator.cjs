// Emulator-only: rewrites descending key scans into ascending scans trimmed in memory.
// Touches only the scratch copy. Results are the same rows; only the query plan differs.
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const wrap = (expr) => `.then(x=>{const docs=${expr};return {docs,empty:docs.length===0,size:docs.length,forEach:(c)=>docs.forEach(c)};})`;
for (const rel of ['core/anchors.js', 'core/dynamic_window.js', 'ddc/vitality_all_in_one.js']) {
  const f = path.join(root, rel);
  let s = fs.readFileSync(f, 'utf8');
  let n = 0;
  s = s.replace(/\.limitToLast\((\w+(?:\s*\+\s*\w+)?)\)\s*\.get\(\)/g, (_, c) => { n++; return `.get()${wrap(`x.docs.slice(-(${c}))`)}`; });
  s = s.replace(/\.orderBy\("__name__",\s*"desc"\)\s*\.limit\((\w+)\)\s*\.get\(\)/g, (_, c) => { n++; return `.orderBy("__name__").get()${wrap(`[...x.docs].reverse().slice(0,${c})`)}`; });
  fs.writeFileSync(f, s);
  console.log(rel, 'rewrites', n);
}
