const svg = document.querySelector('#jelly');
const float = svg.querySelector('.float');
const bell = svg.querySelector('.bell');
const middle = svg.querySelector('.middle');
const lower = svg.querySelector('.lower');
const tail = svg.querySelector('.tail');
const pauseButton = document.querySelector('#pause');
const stillButton = document.querySelector('#still');
const speedControl = document.querySelector('#motion');
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
let paused = reducedMotion.matches;
let originalPose = reducedMotion.matches;
let elapsed = 0;
let lastFrame = null;
let frame = null;

function transformAround(x, y, rotation, sx, sy, dx = 0, dy = 0) {
  return `translate(${x + dx} ${y + dy}) rotate(${rotation}) scale(${sx} ${sy}) translate(${-x} ${-y})`;
}

function render() {
  if (originalPose) {
    for (const layer of [float, bell, middle, lower, tail]) layer.removeAttribute('transform');
    return;
  }
  const phase = elapsed * Math.PI * 2 / 7.5;
  const pulse = Math.sin(phase);
  const middlePulse = Math.sin(phase - .48);
  const lowerPulse = Math.sin(phase - .95);
  const tailPulse = Math.sin(phase - 1.5);
  float.setAttribute('transform', transformAround(630, 585, Math.sin(phase * .5) * 1.15, 1, 1, Math.sin(phase * .5) * 8, -pulse * 15));
  bell.setAttribute('transform', transformAround(640, 390, pulse * .25, 1 + pulse * .018, 1 - pulse * .016));
  middle.setAttribute('transform', transformAround(631, 503, middlePulse * .8, 1 + middlePulse * .022, 1 - middlePulse * .026, middlePulse * 3, middlePulse * 3));
  lower.setAttribute('transform', transformAround(600, 662, lowerPulse * 1.8, 1 + lowerPulse * .025, 1 - lowerPulse * .035, lowerPulse * 5, lowerPulse * 5));
  tail.setAttribute('transform', transformAround(565, 792, tailPulse * 4, 1 + tailPulse * .025, 1 - tailPulse * .025, lowerPulse * 6, lowerPulse * 5));
}

function tick(now) {
  frame = null;
  if (lastFrame !== null) elapsed += Math.min((now - lastFrame) / 1000, .05) * Number(speedControl.value);
  lastFrame = now;
  render();
  schedule();
}

function schedule() {
  if (frame !== null) cancelAnimationFrame(frame);
  frame = null;
  if (!paused && !originalPose && !document.hidden) frame = requestAnimationFrame(tick);
  else lastFrame = null;
}

function updateControls() {
  pauseButton.textContent = paused ? 'Play' : 'Pause';
  pauseButton.setAttribute('aria-pressed', String(paused));
  stillButton.setAttribute('aria-pressed', String(originalPose));
  stillButton.textContent = originalPose ? 'Animate' : 'Original pose';
}

pauseButton.addEventListener('click', () => {
  paused = !paused;
  if (!paused) originalPose = false;
  updateControls();
  schedule();
});

stillButton.addEventListener('click', () => {
  originalPose = !originalPose;
  paused = originalPose;
  render();
  updateControls();
  schedule();
});

document.addEventListener('visibilitychange', schedule);
reducedMotion.addEventListener('change', () => {
  paused = reducedMotion.matches;
  originalPose = reducedMotion.matches;
  render();
  updateControls();
  schedule();
});

render();
updateControls();
schedule();
