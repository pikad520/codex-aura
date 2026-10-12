/* Native companion renderer. Texture deformation is shared with the original demo. */
function clamp(v) { return Math.max(0, Math.min(1, v)); }
function smooth(a, b, t) { const x = clamp((t-a)/(b-a)); return x*x*(3-2*x); }
function cycleAt(elapsed, reduced = false) {
  if (reduced) return {outline: 1, color: 1, settled: 1, fade: 1};
  const t = elapsed;
  return {outline: smooth(0, 1.4, t), color: smooth(1.6, 5.8, t),
    settled: smooth(5.2, 7, t), fade: 1};
}
if (typeof module !== 'undefined') module.exports = {cycleAt};
if (typeof document !== 'undefined') (async function () {
  const canvas = document.getElementById('scene'), ctx = canvas.getContext('2d');
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  let active = false, ready = false, time = 0, last = 0, raf = 0, frames = 0;
  let appearance = {opacity:.20, saturation:1.3, contrast:1.1, brightness:.7};
  let editing = false, width = 1, height = 1, rig;
  function report(value) {
    window.webkit?.messageHandlers?.aura?.postMessage(value);
    canvas.dataset.status = value.status;
  }
  function resize() {
    width = innerWidth; height = innerHeight;
    // One backing pixel per point: an ambient layer does not need retina rendering.
    canvas.width = width; canvas.height = height;
    if (ready) draw();
  }
  function draw() {
    const state = cycleAt(time, reduced.matches);
    const scale = Math.max(width/1672, height/941);
    const x = (width-1672*scale)*.72, y = (height-941*scale)/2;
    const blink = reduced.matches ? 0 : blinkAt(time);
    const wind = reduced.matches ? 0 : state.outline;
    const scanY = y+941*scale*state.color;
    ctx.clearRect(0, 0, width, height);
    ctx.globalCompositeOperation = 'source-over';
    ctx.globalAlpha = 1;
    if (state.color > 0) {
      const character = rig.render(time, blink, wind, 0);
      ctx.save(); ctx.beginPath(); ctx.rect(0, 0, width, Math.max(0, scanY)); ctx.clip();
      ctx.globalAlpha = reduced.matches ? 1 : smooth(1.6, 2.1, time);
      ctx.drawImage(character, x, y, 1672*scale, 941*scale); ctx.restore();
    }
    if (state.settled < 1) {
      const lines = rig.render(time, blink, wind, 0, true);
      ctx.globalCompositeOperation = 'screen';
      ctx.globalAlpha = state.outline*(1-state.settled);
      ctx.drawImage(lines, x, y, 1672*scale, 941*scale);
      if (state.color > 0 && state.color < 1) {
        ctx.globalAlpha = .7; ctx.fillStyle = '#ffe5a0';
        ctx.fillRect(0, scanY, width, 1.5);
      }
    }
    // Sparse slow flecks; avoid code rain over the user's text.
    ctx.globalCompositeOperation = 'screen'; ctx.fillStyle = '#ffdb8a';
    if (!reduced.matches) for (let i = 0; i < 18; i++) {
      ctx.globalAlpha = (.15+.12*Math.sin(time*.8+i))*state.outline;
      const px = ((i*.6180339)%1)*width + Math.sin(time*.25+i)*8;
      const py = ((i*.381966*height-time*(2+i%3))%height+height)%height;
      ctx.beginPath(); ctx.arc(px, py, .7+i%3*.25, 0, Math.PI*2); ctx.fill();
    }
    ctx.globalAlpha = 1; ctx.globalCompositeOperation = 'source-over';
    // Values come directly from the native controls; no hidden opacity multiplier.
    canvas.style.filter = `saturate(${appearance.saturation}) contrast(${appearance.contrast}) brightness(${appearance.brightness})`;
    const baseOpacity = appearance.opacity;
    // Reveal once per launch or explicit Replay; background/foreground changes preserve time.
    const intro = reduced.matches || editing ? 0 : (1-smooth(3.5, 7, time))*.24;
    canvas.style.opacity = String(Math.max(baseOpacity, Math.min(.42, baseOpacity+intro)));
    canvas.dataset.time = time.toFixed(2); canvas.dataset.frames = String(++frames);
    canvas.dataset.blink = blink.toFixed(3); canvas.dataset.active = String(active);
  }
  function frame(now) {
    raf = 0;
    if (!active || !ready || reduced.matches) return;
    if (!last) last = now;
    const dt = now-last;
    if (dt >= 1000/30-1) { time += Math.min(dt/1000, .1); last = now; draw(); }
    raf = requestAnimationFrame(frame);
  }
  function start() { if (active && ready && !raf && !reduced.matches) raf = requestAnimationFrame(frame); }
  window.aura = {
    setActive(value) {
      active = !!value; cancelAnimationFrame(raf); raf = 0; last = 0;
      canvas.dataset.active = String(active);
      if (ready && active) { draw(); start(); }
    },
    setAppearance(value, liveEdit = false) {
      for (const [key, min, max] of [['opacity',0,1],['saturation',0,2],['contrast',.5,2],['brightness',.2,1.5]]) {
        if (typeof value?.[key] === 'number' && Number.isFinite(value[key]))
          appearance[key] = Math.min(max, Math.max(min, value[key]));
      }
      if (liveEdit) editing = true;
      if (ready) draw();
    },
    replay() { time = 0; last = 0; editing = false; if (ready) { draw(); start(); } },
    status() { return {ready, active, frames, time, reduced: reduced.matches, appearance:{...appearance},
      displayOpacity: Number(canvas.style.opacity), reveal: cycleAt(time, reduced.matches)}; }
  };
  addEventListener('resize', resize);
  reduced.addEventListener('change', () => window.aura.setActive(active));
  resize();
  try {
    const images = await Promise.all(['character.png','closed-eye.png','contours.png','closed-contours.png'].map(name =>
      new Promise((resolve, reject) => { const image = new Image(); image.onload = () => resolve(image); image.onerror = () => reject(Error(name)); image.src = window.AURA_TEXTURES?.[name] || 'assets/'+name; })));
    for (const i of [2,3]) {
      const surface = document.createElement('canvas'); surface.width = 1672; surface.height = 941;
      const tint = surface.getContext('2d'); tint.drawImage(images[i], 0, 0);
      tint.globalCompositeOperation = 'multiply'; tint.fillStyle = '#ffe4a0'; tint.fillRect(0, 0, 1672, 941); images[i] = surface;
    }
    const originalWarn = console.warn;
    let rigError = '';
    console.warn = (...args) => { rigError = args.join(' '); originalWarn(...args); };
    try { rig = createCharacterRig(...images); } finally { console.warn = originalWarn; }
    if (!rig || !ctx) throw Error(rigError || 'WebGL context unavailable');
    ready = true; draw(); report({status:'ready'}); start();
  } catch (error) { report({status:'error', message:String(error)}); }
})();
