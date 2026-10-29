// Browser-only fixtures are intercepted at the network boundary.
// The production build has no mock/demo data path.
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { spawn } from 'node:child_process';
import { setTimeout as pause } from 'node:timers/promises';

const root = process.cwd();
const output = path.join(root, 'docs', 'screenshots');
fs.mkdirSync(output, { recursive: true });
const mime = {'.html':'text/html','.js':'text/javascript','.json':'application/json',
  '.wasm':'application/wasm','.ttf':'font/ttf','.otf':'font/otf','.png':'image/png','.jpg':'image/jpeg'};
const server = http.createServer((req, res) => {
  const relative = decodeURIComponent(new URL(req.url, 'http://localhost').pathname).replace(/^\/+/, '');
  const file = path.resolve(root, 'build/web', relative || 'index.html');
  if (!file.startsWith(path.resolve(root, 'build/web') + path.sep)) { res.writeHead(403).end(); return; }
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404).end(); return; }
    res.writeHead(200, {'Content-Type': mime[path.extname(file)] || 'application/octet-stream'});
    res.end(data);
  });
});
await new Promise((ok, no) => { server.once('error', no); server.listen(8765, '127.0.0.1', ok); });
const browser = spawn('C:/Program Files/Google/Chrome/Application/chrome.exe', [
  '--headless=new','--no-sandbox','--disable-gpu','--no-first-run','--disable-extensions',
  '--disable-background-networking','--remote-debugging-port=9333','--remote-allow-origins=*',
  '--user-data-dir=' + path.join(root,'.tooling','chrome-visual'), 'about:blank',
], { windowsHide: true, stdio: ['ignore','ignore','pipe'] });
let browserLog = '';
browser.stderr.on('data', b => browserLog += b);
let ws;
const records = { fixture: true, viewports: [], errors: [], checks: [] };
try {
  let target;
  for (let i=0; i<100; i++) {
    try { target = (await (await fetch('http://127.0.0.1:9333/json/list')).json()).find(t => t.type === 'page'); }
    catch {}
    if (target) break;
    await pause(100);
  }
  if (!target) throw Error('Chrome debugging endpoint unavailable: ' + browserLog.slice(-1000));
  ws = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((ok, no) => { ws.addEventListener('open', ok, {once:true}); ws.addEventListener('error', no, {once:true}); });
  let id=0;
  const pending = new Map();
  const events = new Map();
  const send = (method, params={}) => new Promise((ok, no) => {
    const n=++id;
    pending.set(n, {ok,no});
    ws.send(JSON.stringify({id:n,method,params}));
  });
  ws.addEventListener('message', async event => {
    const msg = JSON.parse(event.data);
    if (msg.id) {
      const item = pending.get(msg.id);
      if (item) { pending.delete(msg.id); msg.error ? item.no(Error(JSON.stringify(msg.error))) : item.ok(msg.result); }
    } else {
      if (msg.method === 'Runtime.exceptionThrown') records.errors.push(msg.params.exceptionDetails);
      if (msg.method === 'Runtime.consoleAPICalled' &&
          msg.params.args?.some(a => String(a.value).includes('OVERFLOWED'))) records.errors.push(msg.params);
      events.get(msg.method)?.(msg.params);
    }
  });
  const fixture = [
    {id:1,name:'Marble Dining Table',price:52999,category:'Dining',rating:5.0,stock:5,
      finishes:['#FFFFFF','#202020'],width_cm:180,depth_cm:90,height_cm:75,
      description:'Elevate your dining space with the Marble Dining Table! Featuring an elegant marble finish and a sturdy, modern base, it brings luxury and sophistication to every meal. Perfect for family dinners, gatherings, and everyday dining, it adds timeless style to your home.',
      reviews:[
        {name:'Sofia Mendoza',rating:5,comment:'The marble finish looks even better in person. It instantly made our dining room feel more elegant.'},
        {name:'Daniel Lim',rating:5,comment:'Sturdy, spacious, and easy to clean. We use it every day and it still looks brand new.'},
        {name:'Camille Torres',rating:5,comment:'Perfect size for family dinners. The modern base is a beautiful touch and the table feels very solid.'},
      ],image_url:''},
    {id:2,name:'Nordic Lounge Chair',price:14999,category:'Living Room',rating:4.7,stock:4,finishes:[],image_url:''},
    {id:3,name:'Linen Slipcover Sofa',price:32999,category:'Living Room',rating:4.7,stock:2,finishes:[],image_url:''},
    {id:4,name:'Scandi Oak Bed',price:28999,category:'Bedroom',rating:4.7,stock:3,finishes:[],image_url:''},
    {id:5,name:'Ergo Office Chair',price:9999,category:'Office',rating:4.7,stock:6,finishes:[],image_url:''},
    {id:6,name:'Walnut Nightstand',price:6999,category:'Bedroom',rating:5.0,stock:0,finishes:[],image_url:''},
  ];
  events.set('Fetch.requestPaused', async p => {
    let data = fixture;
    if (p.request.url.includes('/jj_orders')) data = [];
    if (p.request.url.includes('/rpc/jj_is_admin')) data = false;
    await send('Fetch.fulfillRequest', { requestId:p.requestId, responseCode:200,
      responseHeaders:[{name:'Content-Type',value:'application/json'},
        {name:'Access-Control-Allow-Origin',value:'*'},
        {name:'Access-Control-Allow-Headers',value:'*'}],
      body:Buffer.from(JSON.stringify(data)).toString('base64') });
  });
  await send('Page.enable'); await send('Runtime.enable');
  await send('Fetch.enable', {patterns:[{urlPattern:'*supabase.co/rest/v1/*'}]});
  async function evaluate(expression) {
    const r = await send('Runtime.evaluate', {expression, awaitPromise:true, returnByValue:true});
    if (r.exceptionDetails) throw Error(JSON.stringify(r.exceptionDetails));
    return r.result.value;
  }
  async function click(x,y) {
    await send('Input.dispatchMouseEvent', {type:'mousePressed',x,y,button:'left',clickCount:1});
    await send('Input.dispatchMouseEvent', {type:'mouseReleased',x,y,button:'left',clickCount:1});
    await pause(250);
  }
  async function shot(name) {
    await pause(500);
    const {data} = await send('Page.captureScreenshot', {format:'png',captureBeyondViewport:false});
    fs.writeFileSync(path.join(output,name+'.png'), Buffer.from(data,'base64'));
  }
  async function labelClick(label) {
    return evaluate("(function(){const es=[...document.querySelectorAll('flt-semantics')];const el=es.find(e=>e.getAttribute('aria-label')==="+JSON.stringify(label)+");if(!el)return false;el.click();return true;})()");
  }
  for (const [width,height] of [[414,896],[360,800],[1440,1000]]) {
    records.viewports.push({width,height});
    await send('Emulation.setDeviceMetricsOverride', {width,height,deviceScaleFactor:1,mobile:false});
    await send('Page.navigate',{url:'http://127.0.0.1:8765/'});
    await pause(4500);
    await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");
    await pause(400);
    const prefix = width+'x'+height;
    // Brand cart, first heart, and detail targets are known from measured reference.
    const left = Math.max(0,(width-1200)/2);
    const contentWidth = Math.min(width,1200);
    const columns = contentWidth >= 1036 ? 4 : contentWidth >= 686 ? 3 : 2;
    const cardWidth = (contentWidth-36-22*(columns-1))/columns;
    await click(left+18+cardWidth-29, 478); // first card heart
    // Add the marble table through its detail action.
    await click(left+65, 535);
    await shot(prefix+'-details');
    if (width === 414) {
      await send('Input.dispatchMouseEvent', {type:'mouseWheel',x:width/2,y:height/2,deltaX:0,deltaY:800});
      await pause(700);
      await shot(prefix+'-details-reviews');
      await send('Input.dispatchMouseEvent', {type:'mouseWheel',x:width/2,y:height/2,deltaX:0,deltaY:-800});
      await pause(300);
    }
    await click(width*.68,height-44);
    await pause(300);
    // Close transient snackbar before screenshot.
    await pause(4200);
    await shot(prefix+'-details-cart');
    await click(left+28, 28);
    await pause(350);
    await shot(prefix+'-shop');
    const navY=height-40;
    for (const [tab,n] of [['cart',2],['dashboard',1],['account',3]]) {
      await click(left+contentWidth*(n+.5)/4,navY);
      await shot(prefix+'-'+tab);
    }
    const semantics = await evaluate("document.body.innerText");
    records.checks.push({viewport:prefix,semantics:semantics.slice(0,1500)});
    await send('Storage.clearDataForOrigin',{origin:'http://127.0.0.1:8765',storageTypes:'all'});
  }
  fs.writeFileSync(path.join(output,'browser-results.json'),JSON.stringify(records,null,2));
  console.log(JSON.stringify({screenshots:fs.readdirSync(output).filter(n=>n.endsWith('.png')),errors:records.errors},null,2));
} finally {
  ws?.close(); browser.kill(); server.close();
}

