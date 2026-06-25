import { orderedRange, calendarPath, dayFromElement } from '../rangeSelect';

describe('orderedRange', () => {
  it('returns the two dates in ascending order', () => {
    expect(orderedRange('2026-03-12', '2026-03-05')).toEqual([
      '2026-03-05',
      '2026-03-12',
    ]);
  });

  it('keeps an already-ordered pair', () => {
    expect(orderedRange('2026-03-05', '2026-03-12')).toEqual([
      '2026-03-05',
      '2026-03-12',
    ]);
  });
});

describe('calendarPath', () => {
  it('builds a calendar URL with start and end', () => {
    expect(calendarPath('2026-03-05', '2026-03-12', '')).toBe(
      '/calendar?start=2026-03-05&end=2026-03-12',
    );
  });

  it('includes type_of when present', () => {
    expect(calendarPath('2026-03-05', '2026-03-12', 'live_stream')).toBe(
      '/calendar?start=2026-03-05&end=2026-03-12&type_of=live_stream',
    );
  });
});

describe('dayFromElement', () => {
  let grid;

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-calendar-grid>
        <a data-calendar-day="2026-03-05"><span>5</span></a>
      </div>
      <a data-calendar-day="2026-04-01">outside</a>
    `;
    grid = document.querySelector('[data-calendar-grid]');
  });

  it('returns the day for an element inside a grid day cell', () => {
    const inner = grid.querySelector('span');
    expect(dayFromElement(inner, grid)).toBe('2026-03-05');
  });

  it('returns null for a null element', () => {
    expect(dayFromElement(null, grid)).toBeNull();
  });

  it('returns null for a day cell outside the grid', () => {
    const outside = document.querySelector('[data-calendar-day="2026-04-01"]');
    expect(dayFromElement(outside, grid)).toBeNull();
  });
});
