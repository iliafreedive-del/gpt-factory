// Uses the environment's Playwright + Chromium; saves actual WebGL screenshots.
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
(async () => {
  const out = process.env.EVIDENCE_DIR ? path.resolve(process.env.EVIDENCE_DIR) : path.resolve(__dirname, '../docs/evidence');
  fs.mkdirSync(out, {recursive:true});
  const browser = await chromium.launch({executablePath:process.env.CHROMIUM_BIN || '/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
  const page = await browser.newPage({viewport:{width:1440,height:900},deviceScaleFactor:1});
  const errors=[];
  page.on('console',m=>{console.log(m.type(),m.text());if(/SCRIPT ERROR|Parse Error|Failed to load script|^ERROR:/.test(m.text())) errors.push(m.text());});
  page.on('pageerror',e=>errors.push(e.message));
  await page.goto(process.env.TARGET_URL || 'http://127.0.0.1:8765/',{waitUntil:'networkidle',timeout:120000});
  const expected=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../data/site.json'),'utf8')).build;
  await page.waitForFunction(v=>window.factoryState?.build===v,expected,{timeout:120000});
  await page.keyboard.press('2');
  await page.waitForFunction(()=>window.factoryState?.view===2,{},{timeout:60000});
  const point=await page.evaluate(()=>window.factoryState.pick_points.lgc);
  await page.mouse.click(point[0],point[1]);
  await page.waitForFunction(()=>window.factoryState?.selected==='lgc',{},{timeout:60000});
  const originalX=await page.evaluate(()=>window.factoryState.selected_x);
  await page.keyboard.press('e');
  await page.waitForFunction(()=>window.factoryState?.edit===true,{},{timeout:60000});
  await page.keyboard.press('ArrowRight');
  await page.waitForFunction(x=>window.factoryState?.selected_x===x+1,originalX,{timeout:60000});
  await page.keyboard.press('ArrowLeft');
  await page.waitForFunction(x=>window.factoryState?.selected_x===x,originalX,{timeout:60000});
  await page.keyboard.press('e');
  console.log('PASS browser picking and reversible one-metre building edit');
  for(const [key,name] of [['5','site-plan'],['1','full-site'],['2','lgc-construction'],['3','loading-yard'],['4','workshops'],['6','eastern-workshop']]) {
    await page.keyboard.press(key);
    await page.waitForFunction(v=>window.factoryState?.view===v,Number(key),{timeout:60000});
    await page.waitForFunction(()=>window.factoryFrame>window.factoryState.capture_frame+6,{},{timeout:120000});
    await page.screenshot({path:path.join(out,name+'.png'),timeout:120000});
    console.log('CAPTURE',name,JSON.stringify(await page.evaluate(()=>({build:window.factoryState.build,map:window.factoryState.map,view:window.factoryState.view}))));
  }
  await page.keyboard.press('1');await page.keyboard.press('l');
  await page.waitForFunction(()=>window.factoryState?.labels===true,{},{timeout:60000});
  await page.waitForFunction(()=>window.factoryFrame>window.factoryState.capture_frame+6,{},{timeout:120000});
  await page.screenshot({path:path.join(out,'labels.png'),timeout:120000});
  await page.setViewportSize({width:800,height:600});
  await page.waitForFunction(()=>window.factoryState.viewport_width===800,{},{timeout:60000});
  await page.waitForFunction(()=>window.factoryFrame>window.factoryState.capture_frame+6,{},{timeout:120000});
  await page.screenshot({path:path.join(out,'compact.png'),timeout:120000});
  await browser.close();
  if(errors.length) throw new Error(errors.join('\n'));
})().catch(e=>{console.error(e);process.exit(1)});
