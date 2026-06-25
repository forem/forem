export function orderedRange(a, b) {
  return a <= b ? [a, b] : [b, a];
}

export function calendarPath(start, end, typeOf) {
  const params = new URLSearchParams({ start, end });
  if (typeOf) params.set('type_of', typeOf);
  return `/calendar?${params.toString()}`;
}

// Returns the calendar-day string for a DOM element inside the grid, or null.
export function dayFromElement(element, grid) {
  if (!element) return null;
  const cell = element.closest('[data-calendar-day]');
  return cell && grid.contains(cell) ? cell.dataset.calendarDay : null;
}

// Paints the --in-range preview between two day strings on the grid.
function paintRange(grid, startDay, hoverDay) {
  const [min, max] = orderedRange(startDay, hoverDay);
  grid.querySelectorAll('[data-calendar-day]').forEach((cell) => {
    const day = cell.dataset.calendarDay;
    cell.classList.toggle('calendar__day--in-range', day >= min && day <= max);
  });
}

function clearPaint(grid) {
  grid
    .querySelectorAll('.calendar__day--in-range')
    .forEach((cell) => cell.classList.remove('calendar__day--in-range'));
}

export function initCalendarDragSelect(grid) {
  if (!grid) return;
  const typeOf = grid.dataset.typeOf || '';
  let anchor = null;

  // Resolves the day cell under the pointer coordinates. Touch drag-selection is
  // skipped to allow vertical scrolling, but mouse/pen pointer types can drag-select.
  // We resolve the cell under coordinates in case the pointer moves outside the target.
  const dayFromPoint = (event) =>
    dayFromElement(document.elementFromPoint(event.clientX, event.clientY), grid);

  grid.addEventListener('pointerdown', (event) => {
    if (!event.isPrimary) return; // ignore secondary touches / non-primary buttons
    if (event.pointerType === 'touch') return; // let touch devices scroll normally
    const day = dayFromElement(event.target, grid);
    if (!day) return;
    event.preventDefault(); // suppress the link nav + native scroll; pointerup drives nav
    anchor = day;
    paintRange(grid, anchor, anchor);
  });

  grid.addEventListener('pointermove', (event) => {
    if (!anchor) return;
    const day = dayFromPoint(event);
    if (day) paintRange(grid, anchor, day);
  });

  document.addEventListener('pointerup', (event) => {
    if (!anchor) return;
    const day = dayFromPoint(event) || dayFromElement(event.target, grid) || anchor;
    const [min, max] = orderedRange(anchor, day);
    anchor = null;
    clearPaint(grid);
    window.location.href = calendarPath(min, max, typeOf);
  });

  // A pointer released outside the window (or a cancelled touch) must not leave
  // a stuck drag painting the grid.
  document.addEventListener('pointercancel', () => {
    if (!anchor) return;
    anchor = null;
    clearPaint(grid);
  });
}
