// stackblur-canvas@2.7.0 downloaded from https://ga.jspm.io/npm:stackblur-canvas@2.7.0/dist/stackblur-es.js

function _typeof(a){_typeof=typeof Symbol==="function"&&typeof Symbol.iterator==="symbol"?function(a){return typeof a}:function(a){return a&&typeof Symbol==="function"&&a.constructor===Symbol&&a!==Symbol.prototype?"symbol":typeof a};return _typeof(a)}function _classCallCheck(a,r){if(!(a instanceof r))throw new TypeError("Cannot call a class as a function")}var a=[512,512,456,512,328,456,335,512,405,328,271,456,388,335,292,512,454,405,364,328,298,271,496,456,420,388,360,335,312,292,273,512,482,454,428,405,383,364,345,328,312,298,284,271,259,496,475,456,437,420,404,388,374,360,347,335,323,312,302,292,282,273,265,512,497,482,468,454,441,428,417,405,394,383,373,364,354,345,337,328,320,312,305,298,291,284,278,271,265,259,507,496,485,475,465,456,446,437,428,420,412,404,396,388,381,374,367,360,354,347,341,335,329,323,318,312,307,302,297,292,287,282,278,273,269,265,261,512,505,497,489,482,475,468,461,454,447,441,435,428,422,417,411,405,399,394,389,383,378,373,368,364,359,354,350,345,341,337,332,328,324,320,316,312,309,305,301,298,294,291,287,284,281,278,274,271,268,265,262,259,257,507,501,496,491,485,480,475,470,465,460,456,451,446,442,437,433,428,424,420,416,412,408,404,400,396,392,388,385,381,377,374,370,367,363,360,357,354,350,347,344,341,338,335,332,329,326,323,320,318,315,312,310,307,304,302,299,297,294,292,289,287,285,282,280,278,275,273,271,269,267,265,263,261,259];var r=[9,11,12,13,13,14,14,15,15,15,15,16,16,16,16,17,17,17,17,17,17,17,18,18,18,18,18,18,18,18,18,19,19,19,19,19,19,19,19,19,19,19,19,19,19,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,21,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,22,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24,24];
/**
 * @param {string|HTMLImageElement} img
 * @param {string|HTMLCanvasElement} canvas
 * @param {Float} radius
 * @param {boolean} blurAlphaChannel
 * @param {boolean} useOffset
 * @param {boolean} skipStyles
 * @returns {undefined}
 */function processImage(a,r,t,e,n,o){typeof a==="string"&&(a=document.getElementById(a));if(a&&(Object.prototype.toString.call(a).slice(8,-1)!=="HTMLImageElement"||"naturalWidth"in a)){var v=n?"offset":"natural";var s=a[v+"Width"];var g=a[v+"Height"];if(Object.prototype.toString.call(a).slice(8,-1)==="ImageBitmap"){s=a.width;g=a.height}typeof r==="string"&&(r=document.getElementById(r));if(r&&"getContext"in r){if(!o){r.style.width=s+"px";r.style.height=g+"px"}r.width=s;r.height=g;var i=r.getContext("2d");i.clearRect(0,0,s,g);i.drawImage(a,0,0,a.naturalWidth,a.naturalHeight,0,0,s,g);isNaN(t)||t<1||(e?processCanvasRGBA(r,0,0,s,g,t):processCanvasRGB(r,0,0,s,g,t))}}}
/**
 * @param {string|HTMLCanvasElement} canvas
 * @param {Integer} topX
 * @param {Integer} topY
 * @param {Integer} width
 * @param {Integer} height
 * @throws {Error|TypeError}
 * @returns {ImageData} See {@link https://html.spec.whatwg.org/multipage/canvas.html#imagedata}
 */function getImageDataFromCanvas(a,r,t,e,n){typeof a==="string"&&(a=document.getElementById(a));if(!a||_typeof(a)!=="object"||!("getContext"in a))throw new TypeError("Expecting canvas with `getContext` method in processCanvasRGB(A) calls!");var o=a.getContext("2d");try{return o.getImageData(r,t,e,n)}catch(a){throw new Error("unable to access image data: "+a)}}
/**
 * @param {HTMLCanvasElement} canvas
 * @param {Integer} topX
 * @param {Integer} topY
 * @param {Integer} width
 * @param {Integer} height
 * @param {Float} radius
 * @returns {undefined}
 */function processCanvasRGBA(a,r,t,e,n,o){if(!(isNaN(o)||o<1)){o|=0;var v=getImageDataFromCanvas(a,r,t,e,n);v=processImageDataRGBA(v,r,t,e,n,o);a.getContext("2d").putImageData(v,r,t)}}
/**
 * @param {ImageData} imageData
 * @param {Integer} topX
 * @param {Integer} topY
 * @param {Integer} width
 * @param {Integer} height
 * @param {Float} radius
 * @returns {ImageData}
 */function processImageDataRGBA(e,n,o,v,s,g){var i=e.data;var c=2*g+1;var f=v-1;var l=s-1;var p=g+1;var m=p*(p+1)/2;var u=new t;var b=u;var x;for(var y=1;y<c;y++){b=b.next=new t;y===p&&(x=b)}b.next=u;var h=null,B=null,C=0,d=0;var I=a[g];var R=r[g];for(var G=0;G<s;G++){b=u;var w=i[d],D=i[d+1],A=i[d+2],S=i[d+3];for(var E=0;E<p;E++){b.r=w;b.g=D;b.b=A;b.a=S;b=b.next}var N=0,_=0,k=0,j=0,F=p*w,H=p*D,T=p*A,W=p*S,O=m*w,L=m*D,M=m*A,q=m*S;for(var z=1;z<p;z++){var J=d+((f<z?f:z)<<2);var K=i[J],P=i[J+1],Q=i[J+2],U=i[J+3];var V=p-z;O+=(b.r=K)*V;L+=(b.g=P)*V;M+=(b.b=Q)*V;q+=(b.a=U)*V;N+=K;_+=P;k+=Q;j+=U;b=b.next}h=u;B=x;for(var X=0;X<v;X++){var Y=q*I>>>R;i[d+3]=Y;if(Y!==0){var Z=255/Y;i[d]=(O*I>>>R)*Z;i[d+1]=(L*I>>>R)*Z;i[d+2]=(M*I>>>R)*Z}else i[d]=i[d+1]=i[d+2]=0;O-=F;L-=H;M-=T;q-=W;F-=h.r;H-=h.g;T-=h.b;W-=h.a;var $=X+g+1;$=C+($<f?$:f)<<2;N+=h.r=i[$];_+=h.g=i[$+1];k+=h.b=i[$+2];j+=h.a=i[$+3];O+=N;L+=_;M+=k;q+=j;h=h.next;var aa=B,ra=aa.r,ta=aa.g,ea=aa.b,na=aa.a;F+=ra;H+=ta;T+=ea;W+=na;N-=ra;_-=ta;k-=ea;j-=na;B=B.next;d+=4}C+=v}for(var oa=0;oa<v;oa++){d=oa<<2;var va=i[d],sa=i[d+1],ga=i[d+2],ia=i[d+3],ca=p*va,fa=p*sa,la=p*ga,pa=p*ia,ma=m*va,ua=m*sa,ba=m*ga,xa=m*ia;b=u;for(var ya=0;ya<p;ya++){b.r=va;b.g=sa;b.b=ga;b.a=ia;b=b.next}var ha=v;var Ba=0,Ca=0,da=0,Ia=0;for(var Ra=1;Ra<=g;Ra++){d=ha+oa<<2;var Ga=p-Ra;ma+=(b.r=va=i[d])*Ga;ua+=(b.g=sa=i[d+1])*Ga;ba+=(b.b=ga=i[d+2])*Ga;xa+=(b.a=ia=i[d+3])*Ga;Ia+=va;Ba+=sa;Ca+=ga;da+=ia;b=b.next;Ra<l&&(ha+=v)}d=oa;h=u;B=x;for(var wa=0;wa<s;wa++){var Da=d<<2;i[Da+3]=ia=xa*I>>>R;if(ia>0){ia=255/ia;i[Da]=(ma*I>>>R)*ia;i[Da+1]=(ua*I>>>R)*ia;i[Da+2]=(ba*I>>>R)*ia}else i[Da]=i[Da+1]=i[Da+2]=0;ma-=ca;ua-=fa;ba-=la;xa-=pa;ca-=h.r;fa-=h.g;la-=h.b;pa-=h.a;Da=oa+((Da=wa+p)<l?Da:l)*v<<2;ma+=Ia+=h.r=i[Da];ua+=Ba+=h.g=i[Da+1];ba+=Ca+=h.b=i[Da+2];xa+=da+=h.a=i[Da+3];h=h.next;ca+=va=B.r;fa+=sa=B.g;la+=ga=B.b;pa+=ia=B.a;Ia-=va;Ba-=sa;Ca-=ga;da-=ia;B=B.next;d+=v}}return e}
/**
 * @param {HTMLCanvasElement} canvas
 * @param {Integer} topX
 * @param {Integer} topY
 * @param {Integer} width
 * @param {Integer} height
 * @param {Float} radius
 * @returns {undefined}
 */function processCanvasRGB(a,r,t,e,n,o){if(!(isNaN(o)||o<1)){o|=0;var v=getImageDataFromCanvas(a,r,t,e,n);v=processImageDataRGB(v,r,t,e,n,o);a.getContext("2d").putImageData(v,r,t)}}
/**
 * @param {ImageData} imageData
 * @param {Integer} topX
 * @param {Integer} topY
 * @param {Integer} width
 * @param {Integer} height
 * @param {Float} radius
 * @returns {ImageData}
 */function processImageDataRGB(e,n,o,v,s,g){var i=e.data;var c=2*g+1;var f=v-1;var l=s-1;var p=g+1;var m=p*(p+1)/2;var u=new t;var b=u;var x;for(var y=1;y<c;y++){b=b.next=new t;y===p&&(x=b)}b.next=u;var h=null;var B=null;var C=a[g];var d=r[g];var I,R;var G=0,w=0;for(var D=0;D<s;D++){var A=i[w],S=i[w+1],E=i[w+2],N=p*A,_=p*S,k=p*E,j=m*A,F=m*S,H=m*E;b=u;for(var T=0;T<p;T++){b.r=A;b.g=S;b.b=E;b=b.next}var W=0,O=0,L=0;for(var M=1;M<p;M++){I=w+((f<M?f:M)<<2);j+=(b.r=A=i[I])*(R=p-M);F+=(b.g=S=i[I+1])*R;H+=(b.b=E=i[I+2])*R;W+=A;O+=S;L+=E;b=b.next}h=u;B=x;for(var q=0;q<v;q++){i[w]=j*C>>>d;i[w+1]=F*C>>>d;i[w+2]=H*C>>>d;j-=N;F-=_;H-=k;N-=h.r;_-=h.g;k-=h.b;I=G+((I=q+g+1)<f?I:f)<<2;W+=h.r=i[I];O+=h.g=i[I+1];L+=h.b=i[I+2];j+=W;F+=O;H+=L;h=h.next;N+=A=B.r;_+=S=B.g;k+=E=B.b;W-=A;O-=S;L-=E;B=B.next;w+=4}G+=v}for(var z=0;z<v;z++){w=z<<2;var J=i[w],K=i[w+1],P=i[w+2],Q=p*J,U=p*K,V=p*P,X=m*J,Y=m*K,Z=m*P;b=u;for(var $=0;$<p;$++){b.r=J;b.g=K;b.b=P;b=b.next}var aa=0,ra=0,ta=0;for(var ea=1,na=v;ea<=g;ea++){w=na+z<<2;X+=(b.r=J=i[w])*(R=p-ea);Y+=(b.g=K=i[w+1])*R;Z+=(b.b=P=i[w+2])*R;aa+=J;ra+=K;ta+=P;b=b.next;ea<l&&(na+=v)}w=z;h=u;B=x;for(var oa=0;oa<s;oa++){I=w<<2;i[I]=X*C>>>d;i[I+1]=Y*C>>>d;i[I+2]=Z*C>>>d;X-=Q;Y-=U;Z-=V;Q-=h.r;U-=h.g;V-=h.b;I=z+((I=oa+p)<l?I:l)*v<<2;X+=aa+=h.r=i[I];Y+=ra+=h.g=i[I+1];Z+=ta+=h.b=i[I+2];h=h.next;Q+=J=B.r;U+=K=B.g;V+=P=B.b;aa-=J;ra-=K;ta-=P;B=B.next;w+=v}}return e}var t=function BlurStack(){_classCallCheck(this,BlurStack);this.r=0;this.g=0;this.b=0;this.a=0;this.next=null};export{t as BlurStack,processCanvasRGB as canvasRGB,processCanvasRGBA as canvasRGBA,processImage as image,processImageDataRGB as imageDataRGB,processImageDataRGBA as imageDataRGBA};

