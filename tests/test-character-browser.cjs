// Optional pixel checks: Playwright with a local Chromium installation. No application runtime dependency.
const {chromium}=require('playwright');
const fs=require('node:fs');
const assert=require('node:assert/strict');
const http=require('node:http');
const path=require('node:path');
const root=path.resolve(__dirname,'../web');
const output=path.resolve(__dirname,'../.build/character-check');
fs.mkdirSync(output,{recursive:true});
(async()=>{
 const server=http.createServer((req,res)=>{
   const file=path.resolve(root,'.'+decodeURIComponent(req.url==='/'?'/index.html':req.url));
   if(!file.startsWith(root+path.sep)){res.writeHead(403).end();return;}
   fs.readFile(file,(error,data)=>{if(error){res.writeHead(404).end();return;}res.setHeader('Content-Type',file.endsWith('.js')?'application/javascript':file.endsWith('.png')?'image/png':'text/html');res.end(data);});
 });
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 let browser;
 try {
 browser=await chromium.launch({headless:true,...(process.env.AURA_BROWSER_CHANNEL?{channel:process.env.AURA_BROWSER_CHANNEL}:{})});
 const page=await browser.newPage({viewport:{width:1672,height:941}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.addInitScript(()=>{window.AURA_INITIAL_APPEARANCE={character:'blue-hime'};});
 await page.goto(`http://127.0.0.1:${server.address().port}/`);
 await page.waitForFunction(()=>window.aura?.status().ready);
 assert.equal(await page.evaluate(()=>window.aura.status().character),'blue-hime','saved blue selection loads first');
 await page.evaluate(()=>window.aura.setAppearance({character:'blue-hime',opacity:1,saturation:1,contrast:1,brightness:1},true));
 await page.waitForFunction(()=>window.aura.status().character==='blue-hime'&&!window.aura.status().loading);
 const result=await page.evaluate(async()=>{
   const images=await Promise.all(auraCharacters['blue-hime'].files.map(src=>new Promise((resolve,reject)=>{const im=new Image();im.onload=()=>resolve(im);im.onerror=reject;im.src='assets/'+src;})));
   const rig=createCharacterRig(...images,...images.map(createCharacterContours),'blue-hime');
   const c=document.createElement('canvas');c.width=1672;c.height=941;const ctx=c.getContext('2d');
   function sample(t,b,w,line=false){ctx.drawImage(rig.render(t,b,w,0,line),0,0);return {url:c.toDataURL(),pixels:ctx.getImageData(0,0,c.width,c.height).data};}
   const open=sample(0,0,0),half=sample(0,.5,0),closed=sample(0,1,0),wind=sample(2,0,1),lines=sample(0,.5,1,true);
   let eyeChanges=0,outsideBlinkChanges=0,hairChanges=0,faceChanges=0,linePixels=0;
   for(let y=0;y<c.height;y++)for(let x=0;x<c.width;x++){
     const i=(y*c.width+x)*4;
     const eye=Math.abs(open.pixels[i]-closed.pixels[i])+Math.abs(open.pixels[i+1]-closed.pixels[i+1])+Math.abs(open.pixels[i+2]-closed.pixels[i+2]);
     const hair=Math.abs(open.pixels[i]-wind.pixels[i])+Math.abs(open.pixels[i+1]-wind.pixels[i+1])+Math.abs(open.pixels[i+2]-wind.pixels[i+2]);
     if(eye>9){if(x>1290&&x<1570&&y>180&&y<375)eyeChanges++;else outsideBlinkChanges++;}
     if(hair>9){hairChanges++;if(x>1360&&y>230&&y<700)faceChanges++;}
     if(lines.pixels[i]>20)linePixels++;
   }
   rig.dispose();return {eyeChanges,outsideBlinkChanges,hairChanges,faceChanges,linePixels,images:{open:open.url,half:half.url,closed:closed.url,wind:wind.url,lines:lines.url}};
 });
 for(const [name,data]of Object.entries(result.images)) fs.writeFileSync(path.join(output,`${name}.png`),Buffer.from(data.split(',')[1],'base64'));
 delete result.images;
 assert(result.eyeChanges>2000);assert.equal(result.outsideBlinkChanges,0);assert(result.hairChanges>10000);assert.equal(result.faceChanges,0);assert(result.linePixels>10000);
 assert.deepEqual(errors,[]);
 fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({browser:browser.version(),...result},null,2));
 console.log(result);
 } finally { await browser?.close(); await new Promise(resolve=>server.close(resolve)); }
})().catch(e=>{console.error(e);process.exit(1)});
