// Optional real WebGL checks; uses the same local Playwright tooling as test-character-browser.cjs.
const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const http=require('node:http');
const path=require('node:path');
const root=path.resolve(__dirname,'../web'), output=path.resolve(__dirname,'../.build/music-check');
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
  const page=await browser.newPage({viewport:{width:1672,height:941}}), errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  await page.goto(`http://127.0.0.1:${server.address().port}/`);
  await page.waitForFunction(()=>window.aura?.status().ready);
  const result=await page.evaluate(async()=>{
   const results={};
   for(const id of ['golden','blue-hime']) {
    const images=await Promise.all(auraCharacters[id].files.map(name=>new Promise((resolve,reject)=>{
     const image=new Image();image.onload=()=>resolve(image);image.onerror=reject;image.src='assets/'+name;
    })));
    if(images.length===2)images.push(...images.map(createCharacterContours));
    const rig=createCharacterRig(...images,id), canvas=document.createElement('canvas');
    canvas.width=1672;canvas.height=941;const ctx=canvas.getContext('2d');
    function sample(t,music){ctx.drawImage(rig.render(t,0,1,0,false,music),0,0);return ctx.getImageData(0,0,1672,941).data;}
    const samples=[];let idleImage,loudImage;
    for(const t of [2,4,6]){
     const idle=sample(t,0);if(t===2)idleImage=canvas.toDataURL();
     const loud=sample(t,1);if(t===2)loudImage=canvas.toDataURL();
     let changed=0,face=0,clothing=0;
     for(let y=0;y<941;y++)for(let x=0;x<1672;x++){
      const i=(y*1672+x)*4;
      if(idle[i]===loud[i]&&idle[i+1]===loud[i+1]&&idle[i+2]===loud[i+2])continue;
      changed++;
      if(id==='golden' ? x>=1095&&y>=240&&y<680 : x>=1155&&y>=150&&y<740)face++;
      if(id==='golden' ? x>=1025&&y>=635 : x>=725&&y>=785)clothing++;
     }
     samples.push({t,changed,face,clothing});
    }
    rig.dispose();results[id]={samples,idleImage,loudImage};
   }
   return results;
  });
  for(const [id,data]of Object.entries(result)){
   for(const name of ['idleImage','loudImage']){
    fs.writeFileSync(path.join(output,`${id}-${name}.png`),Buffer.from(data[name].split(',')[1],'base64'));delete data[name];
   }
   for(const sample of data.samples){
    assert(sample.changed>10000,`${id} t=${sample.t}: music visibly changes hair`);
    assert.equal(sample.face,0,`${id} t=${sample.t}: no additional ear/face deformation`);
    assert.equal(sample.clothing,0,`${id} t=${sample.t}: no additional clothing deformation`);
   }
  }
  assert.deepEqual(errors,[]);
  fs.writeFileSync(path.join(output,'result.json'),JSON.stringify({browser:browser.version(),...result},null,2));
  console.log('PASS: maximum music gain changes both characters at three phases, with zero additional face/clothing pixels',result);
 }finally{await browser?.close();await new Promise(resolve=>server.close(resolve));}
})().catch(error=>{console.error(error);process.exit(1);});
