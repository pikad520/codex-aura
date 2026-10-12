/* Static-texture rig. Coordinates are in the newly generated 1672 x 941 golden character. */
function blinkEnvelope(age) {
  if(age<0||age>=.38)return 0;
  if(age<.11)return smooth(0,.11,age);
  if(age<.155)return 1;
  return 1-smooth(.155,.38,age);
}
function blinkAt(seconds) {
  if(seconds<8)return Math.max(...[.95,2.6,5.1].map(start=>blinkEnvelope(seconds-start)));
  const phase=(seconds-8)%12;
  return Math.max(...[0,4.6,9.2,9.7].map(start=>blinkEnvelope(phase-start)));
}
function createCharacterRig(photo,closed,edges,closedEdges) {
  const surface=document.createElement('canvas');surface.width=photo.width;surface.height=photo.height;
  const gl=surface.getContext('webgl',{alpha:false,antialias:false,preserveDrawingBuffer:true});
  if(!gl)return null;
  const vertex=`attribute vec2 position; varying vec2 uv;void main(){uv=vec2((position.x+1.0)*.5,(1.0-position.y)*.5);gl_Position=vec4(position,0.,1.);}`;
  const fragment=`precision mediump float;
  varying vec2 uv;uniform sampler2D opened;uniform sampler2D shut;
  uniform float clock,blink,wind,gaze;
  const vec2 size=vec2(1672.,941.);
  float band(float v,float a,float b,float feather){return smoothstep(a,a+feather,v)*(1.-smoothstep(b-feather,b,v));}
  vec2 hairOffset(vec2 p){
    // Broad curls follow S-shaped paths, with anchored roots and delayed tips.
    float down=smoothstep(70.,880.,p.y);
    float outerCenter=880.-.53*p.y+100.*sin(p.y*.011+.2);
    float middleCenter=1080.-.24*p.y+90.*sin(p.y*.012);
    float outer=exp(-pow((p.x-outerCenter)/155.,2.))*down;
    float middle=exp(-pow((p.x-middleCenter)/135.,2.))*down;
    float right=exp(-pow((p.x-1610.)/92.,2.))*smoothstep(70.,620.,p.y);
    float crown=exp(-pow((p.x-1140.)/160.,2.))*band(p.y,10.,320.,85.);
    float face=smoothstep(1220.,1290.,p.x)*band(p.y,115.,660.,45.);
    float shoulder=smoothstep(1080.,1200.,p.x)*smoothstep(630.,740.,p.y);
    float dx=outer*(sin(clock*1.02-p.y*.004)*13.+sin(clock*1.8+1.)*2.)
      +middle*sin(clock*1.21-p.y*.003+1.3)*8.
      +right*sin(clock*1.13-p.y*.004+2.)*5.
      +crown*sin(clock*1.25)*2.;
    dx+=gaze*(outer*3.+middle*2.+right);
    float dy=outer*sin(clock*.94-p.y*.004)*3.+middle*sin(clock*1.1+1.2)*2.;
    return vec2(dx,dy)*wind*(1.-face)*(1.-shoulder);
  }
  vec2 eyeLocal(vec2 p){vec2 d=p-vec2(1400.,306.);return vec2(.9759*d.x-.2182*d.y,.2182*d.x+.9759*d.y);}
  vec2 eyePixel(vec2 q){return vec2(1400.,306.)+vec2(.9759*q.x+.2182*q.y,-.2182*q.x+.9759*q.y);}

  vec4 eye(vec2 p){
    if(blink>.999)return texture2D(shut,p/size);
    vec2 q=eyeLocal(p);
    float center=q.x/100.;
    float top=-68.+50.*center*center;
    float bottom=56.-42.*center*center;
    float seam=8.+14.*center*center;
    float a=mix(top,seam,blink),b=mix(bottom,seam,blink);
    float openY=q.y,closedY=q.y;
    if(q.y<a){
      float ratio=clamp((q.y+86.)/max(a+86.,1.),0.,1.);
      openY=mix(-86.,top,ratio);closedY=mix(-86.,mix(-18.,seam,smoothstep(.72,1.,blink)),ratio);
    }else if(q.y>b){
      float ratio=clamp((q.y-b)/max(84.-b,1.),0.,1.);
      openY=mix(bottom,84.,ratio);closedY=mix(mix(64.,seam,smoothstep(.72,1.,blink)),84.,ratio);
    }else{
      openY=mix(top,bottom,clamp((q.y-a)/max(b-a,.1),0.,1.));
      return texture2D(opened,eyePixel(vec2(q.x,openY))/size);
    }
    return mix(texture2D(opened,eyePixel(vec2(q.x,openY))/size),texture2D(shut,eyePixel(vec2(q.x,closedY))/size),smoothstep(0.,.2,blink));
  }
  void main(){
    vec2 p=uv*size;vec2 warped=p+hairOffset(p);
    vec4 base=texture2D(opened,warped/size);
    vec2 q=eyeLocal(p);float mask=band(q.x,-119.,119.,12.)*band(q.y,-86.,84.,12.);
    if(blink>.0001&&mask>0.)base=mix(base,eye(p),mask);
    gl_FragColor=base;
  }`;
  function shader(type,source){const s=gl.createShader(type);gl.shaderSource(s,source);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(s));return s;}
  let program;
  try{program=gl.createProgram();gl.attachShader(program,shader(gl.VERTEX_SHADER,vertex));gl.attachShader(program,shader(gl.FRAGMENT_SHADER,fragment));gl.linkProgram(program);if(!gl.getProgramParameter(program,gl.LINK_STATUS))throw Error(gl.getProgramInfoLog(program));}
  catch(error){console.warn('Character deformation unavailable:',error.message);return null;}
  gl.useProgram(program);const buffer=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,buffer);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-1,-1,1,-1,-1,1,-1,1,1,-1,1,1]),gl.STATIC_DRAW);
  const position=gl.getAttribLocation(program,'position');gl.enableVertexAttribArray(position);gl.vertexAttribPointer(position,2,gl.FLOAT,false,0,0);
  const textures=[];
  try{[photo,closed,edges,closedEdges].forEach(image=>{const texture=gl.createTexture();textures.push(texture);gl.bindTexture(gl.TEXTURE_2D,texture);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,image);});
    gl.uniform1i(gl.getUniformLocation(program,'opened'),0);gl.uniform1i(gl.getUniformLocation(program,'shut'),1);
  }catch(error){console.warn('Character textures unavailable:',error.message);return null;}
  const uniforms=Object.fromEntries(['clock','blink','wind','gaze'].map(name=>[name,gl.getUniformLocation(program,name)]));
  let lost=false;surface.addEventListener('webglcontextlost',event=>{event.preventDefault();lost=true;});
  return {render(clock,blink,wind,gaze,linework=false){if(lost)return linework?edges:photo;const offset=linework?2:0;for(let unit=0;unit<2;unit++){gl.activeTexture(gl.TEXTURE0+unit);gl.bindTexture(gl.TEXTURE_2D,textures[offset+unit]);}gl.uniform1f(uniforms.clock,clock);gl.uniform1f(uniforms.blink,blink);gl.uniform1f(uniforms.wind,wind);gl.uniform1f(uniforms.gaze,gaze);gl.drawArrays(gl.TRIANGLES,0,6);return surface;}};
}
if(typeof module!=='undefined')module.exports={blinkEnvelope,blinkAt};
