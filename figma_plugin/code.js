// MazaTalk Wireframe Generator
// Adds the 9 missing screens to the existing Figma file.
// Run via: Plugins > Development > Import plugin from manifest → run once.

const W = 393;
const H = 852;
const PAD = 24;
const STATUS_H = 60;
const HOME_H = 34;
const CONTENT_TOP = STATUS_H + 12;

const FONT_REG  = { family: 'Inter', style: 'Regular' };
const FONT_MED  = { family: 'Inter', style: 'Medium' };
const FONT_BOLD = { family: 'Inter', style: 'Bold' };

const C = {
  white:  { r: 1,    g: 1,    b: 1    },
  black:  { r: 0,    g: 0,    b: 0    },
  gray50: { r: 0.97, g: 0.97, b: 0.97 },
  gray200:{ r: 0.88, g: 0.88, b: 0.88 },
  gray400:{ r: 0.70, g: 0.70, b: 0.70 },
  gray600:{ r: 0.45, g: 0.45, b: 0.45 },
  green:  { r: 0.87, g: 0.97, b: 0.87 },
};

// ─── Primitives ───────────────────────────────────────────────────────────────

function rect(parent, x, y, w, h, { fill = C.gray50, radius = 0, stroke, sw = 1.5 } = {}) {
  const r = figma.createRectangle();
  r.resize(w, h);
  r.x = x; r.y = y;
  r.fills = [{ type: 'SOLID', color: fill }];
  r.cornerRadius = radius;
  if (stroke) {
    r.strokes = [{ type: 'SOLID', color: stroke }];
    r.strokeWeight = sw;
    r.strokeAlign = 'INSIDE';
  }
  parent.appendChild(r);
  return r;
}

function text(parent, str, x, y, { font = FONT_REG, size = 16, color = C.black, w, align } = {}) {
  const t = figma.createText();
  t.fontName = font;
  t.fontSize = size;
  t.fills = [{ type: 'SOLID', color }];
  if (w) { t.textAutoResize = 'HEIGHT'; t.resize(w, 40); }
  t.characters = str;
  if (align) t.textAlignHorizontal = align;
  t.x = x; t.y = y;
  parent.appendChild(t);
  return t;
}

function button(parent, label, x, y, w = W - PAD * 2, { outline = false } = {}) {
  const bg = outline ? C.white : C.black;
  const fg = outline ? C.black : C.white;
  rect(parent, x, y, w, 52, { fill: bg, radius: 14, stroke: outline ? C.black : null, sw: 2 });
  text(parent, label, x, y + 15, { font: FONT_BOLD, size: 16, color: fg, w, align: 'CENTER' });
}

function input(parent, placeholder, x, y, w = W - PAD * 2) {
  rect(parent, x, y, w, 52, { fill: C.white, radius: 12, stroke: C.gray200, sw: 1.5 });
  text(parent, placeholder, x + 16, y + 16, { color: C.gray400, size: 15 });
}

function label(parent, str, x, y) {
  text(parent, str, x, y, { font: FONT_MED, size: 13, color: C.gray600 });
}

function frame(name, x, y) {
  const f = figma.createFrame();
  f.name = name;
  f.resize(W, H);
  f.x = x; f.y = y;
  f.fills = [{ type: 'SOLID', color: C.white }];
  return f;
}

function statusBar(f) {
  rect(f, 0, 0, W, STATUS_H, { fill: C.white });
  text(f, '9:41', PAD, 22, { font: FONT_BOLD, size: 14 });
  text(f, '●●● ▲ ■', W - 100, 22, { font: FONT_REG, size: 12, color: C.gray400 });
}

function homeBar(f) {
  rect(f, (W - 134) / 2, H - 18, 134, 5, { fill: C.black, radius: 3 });
}

function appBar(f, title, { back = true, subtitle } = {}) {
  if (back) text(f, '‹', PAD, CONTENT_TOP + 4, { font: FONT_BOLD, size: 24, color: C.gray600 });
  text(f, title, PAD, CONTENT_TOP + 36, { font: FONT_BOLD, size: 22, w: W - PAD * 2 });
  if (subtitle) text(f, subtitle, PAD, CONTENT_TOP + 68, { size: 14, color: C.gray600, w: W - PAD * 2 });
}

// ─── Screens ─────────────────────────────────────────────────────────────────

async function welcome(f) {
  // Hero illustration placeholder
  rect(f, (W - 120) / 2, 160, 120, 120, { fill: C.gray200, radius: 28 });
  text(f, 'LOGO', (W - 120) / 2 + 32, 210, { font: FONT_BOLD, size: 20, color: C.gray400 });

  text(f, 'MazaTalk', PAD, 318, { font: FONT_BOLD, size: 34, w: W - PAD * 2, align: 'CENTER' });
  text(f, 'Learning adventures for little explorers', PAD, 364, { size: 15, color: C.gray600, w: W - PAD * 2, align: 'CENTER' });

  button(f, 'Log in', PAD, 460);
  button(f, 'Create an account', PAD, 528, W - PAD * 2, { outline: true });

  text(f, 'By continuing you agree to our Terms of Service', PAD, 620, { size: 12, color: C.gray400, w: W - PAD * 2, align: 'CENTER' });
}

async function verifyCode(f) {
  appBar(f, 'Enter the code', { subtitle: 'We sent a 6-digit code to +1 555 000 0000' });

  const boxW = 44;
  const gap = 10;
  const totalW = boxW * 6 + gap * 5;
  const startX = (W - totalW) / 2;
  for (let i = 0; i < 6; i++) {
    rect(f, startX + i * (boxW + gap), 260, boxW, 56, { fill: C.white, radius: 10, stroke: C.gray200, sw: 2 });
  }
  // First box looks "active"
  rect(f, startX, 260, boxW, 56, { fill: C.white, radius: 10, stroke: C.black, sw: 2 });

  button(f, 'Verify code', PAD, 358);
  text(f, "Didn't get it? Resend code", PAD, 432, { size: 14, color: C.gray600, w: W - PAD * 2, align: 'CENTER' });
  text(f, 'For phone: also try Log in with email', PAD, 460, { size: 12, color: C.gray400, w: W - PAD * 2, align: 'CENTER' });
}

async function resetPassword(f) {
  appBar(f, 'Reset password', { subtitle: 'Enter your email and we\'ll send a link.' });

  label(f, 'Email address', PAD, 272);
  input(f, 'parent@email.com', PAD, 294);

  button(f, 'Send reset link', PAD, 374);
  text(f, 'Back to login', PAD, 448, { size: 14, color: C.gray600, w: W - PAD * 2, align: 'CENTER' });
}

async function success(f) {
  // Check circle
  rect(f, (W - 88) / 2, 250, 88, 88, { fill: C.gray50, radius: 44 });
  // Inner check mark represented as text
  text(f, 'OK', (W - 88) / 2 + 22, 278, { font: FONT_BOLD, size: 28, color: C.black });

  text(f, 'Password reset!', PAD, 374, { font: FONT_BOLD, size: 26, w: W - PAD * 2, align: 'CENTER' });
  text(f, 'Check your inbox for a link to choose a new password.', PAD, 416, { size: 14, color: C.gray600, w: W - PAD * 2, align: 'CENTER' });

  button(f, 'Back to login', PAD, 500);
}

async function interestSelect(f) {
  appBar(f, 'What does\nAlex love?', { back: false, subtitle: 'Pick at least one — we\'ll build their world around it.' });

  const topics = [
    'Dinosaurs', 'Cars', 'Trains', 'Space',
    'Ocean', 'Animals', 'Music', 'Art',
    'Fairy Tales', 'Sports',
  ];
  const cols = 2;
  const cW = (W - PAD * 2 - 12) / 2;
  const cH = 58;

  topics.forEach((t, i) => {
    const col = i % cols;
    const row = Math.floor(i / cols);
    const x = PAD + col * (cW + 12);
    const y = 230 + row * (cH + 10);
    // Some look selected
    const selected = i < 2;
    rect(f, x, y, cW, cH, {
      fill: selected ? C.black : C.gray50,
      radius: 14,
      stroke: selected ? null : C.gray200,
      sw: 1.5,
    });
    text(f, t, x + 16, y + (cH - 18) / 2, { font: FONT_MED, size: 15, color: selected ? C.white : C.black });
  });

  button(f, 'Next  →', PAD, H - HOME_H - PAD - 52);
}

async function lessonPlayer(f) {
  statusBar(f);

  // AppBar with title + coin count
  text(f, 'Dinosaur World  •  Lesson 1', PAD, CONTENT_TOP + 8, { font: FONT_BOLD, size: 15, w: W - 100 });
  text(f, '60 coins', W - 90, CONTENT_TOP + 8, { font: FONT_MED, size: 13, color: C.gray600 });

  // Progress bar (5 segments, 2 done)
  const segW = (W - PAD * 2 - 16) / 5;
  for (let i = 0; i < 5; i++) {
    rect(f, PAD + i * (segW + 4), CONTENT_TOP + 34, segW, 6, {
      fill: i < 2 ? C.black : C.gray200,
      radius: 3,
    });
  }

  // Prompt
  text(f, 'How many dinosaurs can you count?', PAD, 175, { font: FONT_BOLD, size: 20, w: W - PAD * 2 });
  // Illustration placeholder
  rect(f, PAD, 225, W - PAD * 2, 140, { fill: C.gray50, radius: 16, stroke: C.gray200, sw: 1 });
  text(f, '[illustration]', PAD + 100, 285, { size: 14, color: C.gray400 });

  // 4 answer choices
  const choices = ['2', '3  (correct)', '4', '5'];
  choices.forEach((c, i) => {
    const y = 390 + i * 62;
    const isCorrect = i === 1;
    rect(f, PAD, y, W - PAD * 2, 50, {
      fill: isCorrect ? C.green : C.white,
      radius: 12,
      stroke: isCorrect ? { r: 0.2, g: 0.7, b: 0.2 } : C.gray200,
      sw: isCorrect ? 2 : 1.5,
    });
    text(f, c, PAD + 16, y + 14, { font: isCorrect ? FONT_BOLD : FONT_REG, size: 16, color: C.black });
  });

  button(f, 'Continue', PAD, H - HOME_H - PAD - 52);
  homeBar(f);
}

async function worldComplete(f) {
  statusBar(f);
  homeBar(f);

  // Confetti blocks (decorative rects)
  [[50, 200, 18, 18], [300, 170, 14, 14], [80, 350, 12, 12], [320, 310, 16, 16]].forEach(([x, y, w, h]) => {
    rect(f, x, y, w, h, { fill: C.gray200, radius: 4 });
  });

  rect(f, (W - 100) / 2, 240, 100, 100, { fill: C.gray50, radius: 50 });
  text(f, 'DONE', (W - 100) / 2 + 18, 278, { font: FONT_BOLD, size: 18, color: C.gray600 });

  text(f, 'World Complete!', PAD, 380, { font: FONT_BOLD, size: 28, w: W - PAD * 2, align: 'CENTER' });
  text(f, "You and Alex finished every lesson in this world. Amazing job!", PAD, 426, { size: 15, color: C.gray600, w: W - PAD * 2, align: 'CENTER' });
  text(f, '+20 coins earned', PAD, 480, { font: FONT_MED, size: 14, color: C.gray400, w: W - PAD * 2, align: 'CENTER' });

  button(f, 'Pick a new skin', PAD, 540);
  button(f, 'Back to lessons', PAD, 608, W - PAD * 2, { outline: true });
}

async function skinSelect(f) {
  appBar(f, 'Pick your look', { back: true, subtitle: 'Spend coins to unlock new characters.' });
  text(f, '60 coins', W - 90, CONTENT_TOP + 36, { font: FONT_BOLD, size: 14, color: C.gray600 });

  const skins = [
    { name: 'Bear',   cost: 'Equipped', free: true  },
    { name: 'Panda',  cost: '50 coins', free: false },
    { name: 'Fox',    cost: '50 coins', free: false },
    { name: 'Frog',   cost: '75 coins', free: false },
    { name: 'Lion',   cost: '75 coins', free: false },
    { name: 'Tiger',  cost: '100 coins', free: false },
  ];

  const cW = (W - PAD * 2 - 14) / 2;
  skins.forEach((s, i) => {
    const col = i % 2;
    const row = Math.floor(i / 2);
    const x = PAD + col * (cW + 14);
    const y = 240 + row * 145;
    rect(f, x, y, cW, 125, { fill: C.gray50, radius: 18, stroke: s.free ? C.black : C.gray200, sw: s.free ? 2 : 1 });
    rect(f, x + 16, y + 14, cW - 32, 68, { fill: C.gray200, radius: 10 });
    text(f, s.name, x + 16, y + 90, { font: FONT_BOLD, size: 14 });
    text(f, s.cost, x + cW - (s.cost.length * 7 + 8), y + 92, { size: 12, color: s.free ? C.black : C.gray600 });
  });
}

async function parentDashboard(f) {
  appBar(f, 'Parent Dashboard', { back: false });

  // Child card
  rect(f, PAD, 240, W - PAD * 2, 82, { fill: C.gray50, radius: 16, stroke: C.gray200, sw: 1 });
  text(f, 'Alex, age 5', PAD + 16, 258, { font: FONT_BOLD, size: 16 });
  text(f, '60 coins earned total', PAD + 16, 284, { size: 13, color: C.gray600 });
  rect(f, W - PAD - 44, 255, 44, 44, { fill: C.gray200, radius: 22 });

  text(f, 'Lesson Progress', PAD, 356, { font: FONT_BOLD, size: 16 });

  const lessons = [
    { name: 'Dinosaur World',  pct: 1.0 },
    { name: 'Space Explorer',  pct: 0.6 },
    { name: 'Ocean Deep',      pct: 0.2 },
    { name: 'Animal Kingdom',  pct: 0.0 },
  ];

  lessons.forEach((l, i) => {
    const y = 392 + i * 74;
    const barW = W - PAD * 2;
    text(f, l.name, PAD, y, { font: FONT_MED, size: 14 });
    text(f, `${Math.round(l.pct * 100)}%`, W - PAD - 36, y, { size: 13, color: C.gray600 });
    rect(f, PAD, y + 24, barW, 10, { fill: C.gray200, radius: 5 });
    if (l.pct > 0) rect(f, PAD, y + 24, barW * l.pct, 10, { fill: C.black, radius: 5 });
  });

  button(f, 'Log out', PAD, H - HOME_H - PAD - 52, W - PAD * 2, { outline: true });
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  await figma.loadFontAsync(FONT_REG);
  await figma.loadFontAsync(FONT_MED);
  await figma.loadFontAsync(FONT_BOLD);

  const page = figma.currentPage;

  // Existing frames occupy rows at y=2 and y=954.
  // New frames continue row 2 (y=954) then start row 3 (y=1906).
  const screens = [
    // ── Row 2 additions (y = 954) ──────────────────────────────────────────
    { name: 'Verify Code',      x:  812, y:  954, fn: verifyCode      },
    { name: 'Reset Password',   x: 1305, y:  954, fn: resetPassword   },
    { name: 'Success',          x: 1798, y:  954, fn: success         },
    // ── Row 3 (y = 1906) ──────────────────────────────────────────────────
    { name: 'Welcome',          x: -174, y: 1906, fn: welcome         },
    { name: 'Interest Select',  x:  319, y: 1906, fn: interestSelect  },
    { name: 'Lesson Player',    x:  812, y: 1906, fn: lessonPlayer    },
    { name: 'World Complete',   x: 1305, y: 1906, fn: worldComplete   },
    { name: 'Skin Select',      x: 1798, y: 1906, fn: skinSelect      },
    { name: 'Parent Dashboard', x: 2291, y: 1906, fn: parentDashboard },
  ];

  for (const s of screens) {
    const f = frame(s.name, s.x, s.y);
    statusBar(f);
    homeBar(f);
    await s.fn(f);
    page.appendChild(f);
  }

  figma.viewport.scrollAndZoomIntoView(page.children);
  figma.closePlugin(`Done — added ${screens.length} wireframe screens.`);
}

main().catch((err) => figma.closePlugin('Error: ' + err.message));
