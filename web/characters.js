/* Bundled character IDs also form the persistent native settings contract. */
const auraCharacters = {
  golden: {files:['character.png','closed-eye.png','contours.png','closed-contours.png'], tint:'#ffe4a0', scan:'#ffe5a0', flecks:'#ffdb8a'},
  'blue-hime': {files:['blue-hime/open.png','blue-hime/closed.png'], tint:'#b5d7ff', scan:'#b5d7ff', flecks:'#b5d7ff'}
};
function auraCharacterID(value) { return value === 'blue-hime' ? value : 'golden'; }

// Derive linework once on load, keeping it perfectly registered with each blink texture.
// The same rig then deforms both the color and line passes.
function createCharacterContours(image) {
  const surface=document.createElement('canvas'); surface.width=image.width; surface.height=image.height;
  const ctx=surface.getContext('2d', {willReadFrequently:true}); ctx.drawImage(image,0,0);
  const {width,height}=surface, source=ctx.getImageData(0,0,width,height);
  const luma=new Float32Array(width*height), output=ctx.createImageData(width,height);
  for(let i=0;i<luma.length;i++) luma[i]=source.data[i*4]*.2126+source.data[i*4+1]*.7152+source.data[i*4+2]*.0722;
  for(let y=1;y<height-1;y++) for(let x=1;x<width-1;x++) {
    const i=y*width+x;
    const gx=-luma[i-width-1]+luma[i-width+1]-2*luma[i-1]+2*luma[i+1]-luma[i+width-1]+luma[i+width+1];
    const gy=-luma[i-width-1]-2*luma[i-width]-luma[i-width+1]+luma[i+width-1]+2*luma[i+width]+luma[i+width+1];
    const edge=Math.min(255,Math.max(0,Math.hypot(gx,gy)-12)*2.2);
    output.data[i*4]=output.data[i*4+1]=output.data[i*4+2]=edge;
  }
  for(let i=3;i<output.data.length;i+=4) output.data[i]=255;
  ctx.putImageData(output,0,0); return surface;
}
