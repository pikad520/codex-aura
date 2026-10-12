const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const {cycleAt} = require('../web/overlay.js');
assert.equal(cycleAt(0).fade, 1);
assert.equal(cycleAt(24).outline, 1);
assert.equal(cycleAt(23.99).fade, 1);
assert.deepEqual(cycleAt(40,true), {outline:1,color:1,settled:1,fade:1});
for (let t=0;t<100;t+=.01) for (const v of Object.values(cycleAt(t))) assert(v>=0 && v<=1);

// Exercise actual scheduling/bridge behavior with a small canvas host, not a copy of the logic.
(async () => {
  let callbacks = new Map(), next = 0, reduced = {matches:false,addEventListener(_,fn){this.changed=fn;}};
  const context2d = new Proxy({}, {get(target,key){return target[key] || (()=>{});}});
  const canvas = {dataset:{},style:{},getContext(){return context2d;}};
  const macMessages = [], windowsMessages = [];
  const sandbox = {console,
    webkit:{messageHandlers:{aura:{postMessage:value=>macMessages.push(value)}}},
    chrome:{webview:{postMessage:value=>windowsMessages.push(value)}}, innerWidth:1280, innerHeight:800, matchMedia:()=>reduced,
    document:{getElementById:()=>canvas,createElement:()=>({getContext:()=>context2d})},
    Image:class {set src(v){queueMicrotask(()=>this.onload());}},
    addEventListener(){}, cancelAnimationFrame(id){callbacks.delete(id);},
    requestAnimationFrame(fn){callbacks.set(++next,fn);return next;},
    blinkAt:()=>0,createCharacterRig:()=>({render:()=>({})})};
  sandbox.window = sandbox;
  vm.runInNewContext(fs.readFileSync(require.resolve('../web/overlay.js'),'utf8'),vm.createContext(sandbox));
  await new Promise(resolve=>setImmediate(resolve));
  assert.equal(sandbox.aura.status().ready,true);
  assert.equal(macMessages[0].status,'ready');
  assert.equal(windowsMessages[0].status,'ready');
  assert.equal(callbacks.size,0,'no animation before native activation');
  sandbox.aura.setActive(true);
  const before = sandbox.aura.status().frames;
  for(let now=1;now<=1001;now+=1000/60){const current=[...callbacks.values()];callbacks.clear();current.forEach(fn=>fn(now));}
  const frames = sandbox.aura.status().frames-before;
  assert(frames>=28 && frames<=31,`30fps budget: ${frames}`);
  sandbox.aura.setActive(false);
  assert.equal(callbacks.size,0,'hidden animation stops RAF entirely');
  const frozen = sandbox.aura.status().time;
  sandbox.aura.setActive(true);
  assert.equal(sandbox.aura.status().time,frozen,'resume preserves progress');
  for(let now=1100;now<=62000;now+=100){const current=[...callbacks.values()];callbacks.clear();current.forEach(fn=>fn(now));}
  assert(sandbox.aura.status().time>48,'character clock keeps advancing beyond both old scan boundaries');
  assert.equal(sandbox.aura.status().reveal.color,1);
  assert.equal(sandbox.aura.status().reveal.fade,1);
  assert(Math.abs(Number(canvas.style.opacity)-.20)<.001,'default actual opacity is 20%');
  assert.equal(canvas.style.filter,'saturate(1.3) contrast(1.1) brightness(0.7)');
  const finishedTime=sandbox.aura.status().time;
  sandbox.aura.setAppearance({opacity:.24,saturation:1.44,contrast:1.22,brightness:.66},true);
  assert.equal(Number(canvas.style.opacity),.24,'panel percentage is actual opacity, with no conversion');
  assert.equal(canvas.style.filter,'saturate(1.44) contrast(1.22) brightness(0.66)');
  assert.equal(sandbox.aura.status().time,finishedTime,'live control changes do not replay the intro');
  sandbox.aura.setActive(false);sandbox.aura.setActive(true);
  assert.equal(sandbox.aura.status().time,finishedTime,'returning to Codex does not replay the intro');
  reduced.matches=true;reduced.changed();
  assert.equal(callbacks.size,0,'Reduce Motion does not run an animation loop');
  sandbox.aura.replay();
  assert.equal(sandbox.aura.status().time,0);
  sandbox.aura.setAppearance({opacity:.20,saturation:1.3,contrast:1.1,brightness:.7},true);
  assert.equal(Number(canvas.style.opacity),.20,'manual changes override intro brightness immediately');
  sandbox.aura.setAppearance({opacity:0,saturation:0},true);
  assert.equal(Number(canvas.style.opacity),0,'zero is a valid value');
  sandbox.aura.setAppearance({opacity:NaN,contrast:99,brightness:-5},true);
  assert.equal(sandbox.aura.status().appearance.opacity,0,'invalid values are ignored');
  assert.equal(sandbox.aura.status().appearance.contrast,2);
  assert.equal(sandbox.aura.status().appearance.brightness,.2);
  console.log('PASS: one-shot reveal, sustained motion clock, live four-parameter appearance, 30fps, pause/resume/replay and reduced motion');
})();
