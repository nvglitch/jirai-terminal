// rhythm.js — maimai b50 / chuni b30

function b50(rows) {
  const best = new Map();
  for (const r of rows) {
    const rating = parseFloat(r.dx_rating) || 0;
    if (rating <= 0) continue;
    const key = r.song_name + "|" + (r.level_index || "3");
    if (!best.has(key) || rating > best.get(key)._r) {
      best.set(key, { ...r, _r: rating });
    }
  }
  return Array.from(best.values())
    .sort((a, b) => b._r - a._r)
    .slice(0, 50);
}

function b30(rows) {
  const best = new Map();
  for (const r of rows) {
    const rating = parseFloat(r.rating) || 0;
    if (rating <= 0) continue;
    const key = r.song_name + "|" + (r.level_index || "3");
    if (!best.has(key) || rating > best.get(key)._r) {
      best.set(key, { ...r, _r: rating });
    }
  }
  return Array.from(best.values())
    .sort((a, b) => b._r - a._r)
    .slice(0, 30);
}

function cmdMaimai() {
  const top = b50(window._maimaiData);
  const total = top.reduce((s, r) => s + r._r, 0);
  window.appendLine("response", `🎧 maimai DX b50 — ${top.length} 曲  total: ${total.toFixed(0)}`);
  window.appendLine("system", "  #  rating  lv    achv      song");
  top.forEach((r, i) => {
    const num = String(i + 1).padStart(3);
    const rat = r._r.toFixed(0).padStart(6);
    const lv = (r.level || "").padEnd(5);
    const sc = (r.achievements || "").padStart(8);
    window.appendLine("info", ` ${num} ${rat} ${lv} ${sc}  ${r.song_name}`);
  });
  window.appendLine("system", `total: ${total.toFixed(0)}  |  avg: ${(total / top.length).toFixed(0)}`);
}

function cmdChuni() {
  const top = b30(window._chuniData);
  const total = top.reduce((s, r) => s + r._r, 0);
  window.appendLine("response", `🎹 CHUNITHM b30 — ${top.length} 曲  total: ${total.toFixed(2)}`);
  window.appendLine("system", "  #  rating   lv    score      song");
  top.forEach((r, i) => {
    const num = String(i + 1).padStart(3);
    const rat = r._r.toFixed(2).padStart(7);
    const lv = (r.level || "").padEnd(5);
    const sc = (r.score || "").padStart(8);
    window.appendLine("info", ` ${num} ${rat} ${lv} ${sc}  ${r.song_name}`);
  });
  window.appendLine("system", `total: ${total.toFixed(2)}  |  avg: ${(total / top.length).toFixed(2)}`);
}
