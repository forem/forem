import { renderHeatmap } from '../heatmap';

describe('renderHeatmap', () => {
  let root;

  beforeEach(() => {
    root = document.createElement('div');
    document.body.appendChild(root);
  });

  afterEach(() => {
    root.remove();
  });

  function makeDays(count, populate = () => 0) {
    const days = [];
    const start = new Date(Date.UTC(2025, 0, 1)); // Wednesday
    for (let i = 0; i < count; i += 1) {
      const d = new Date(start);
      d.setUTCDate(d.getUTCDate() + i);
      const iso = d.toISOString().slice(0, 10);
      const total = populate(i);
      days.push({ date: iso, articles: 0, comments: 0, reactions: 0, total });
    }
    return days;
  }

  it('renders one cell per day plus leading blanks aligned to the weekday row', () => {
    const days = makeDays(7);
    renderHeatmap(root, { days, max: 0 });

    const cells = root.querySelectorAll('.heatmap__cells > .heatmap__cell');
    // Jan 1 2025 is a Wednesday (UTC day 3) → 3 leading blanks + 7 real cells.
    expect(cells.length).toBe(10);
    expect(root.querySelectorAll('.heatmap__cell--blank').length).toBe(3);
  });

  it('assigns color buckets by ratio to max', () => {
    const days = [
      { date: '2025-01-01', articles: 0, comments: 0, reactions: 0, total: 0 },
      { date: '2025-01-02', articles: 0, comments: 0, reactions: 0, total: 1 },
      { date: '2025-01-03', articles: 0, comments: 0, reactions: 0, total: 5 },
      { date: '2025-01-04', articles: 0, comments: 0, reactions: 0, total: 10 },
    ];
    renderHeatmap(root, { days, max: 10 });

    const realCells = Array.from(
      root.querySelectorAll('.heatmap__cells > .heatmap__cell'),
    ).filter((c) => !c.classList.contains('heatmap__cell--blank'));

    expect(realCells[0].dataset.level).toBe('0');
    expect(realCells[1].dataset.level).toBe('1');
    expect(realCells[2].dataset.level).toBe('2');
    expect(realCells[3].dataset.level).toBe('4');
  });

  it('renders an empty-state message when there are no days', () => {
    renderHeatmap(root, { days: [], max: 0 }, { emptyLabel: 'Nothing yet' });
    expect(root.textContent).toContain('Nothing yet');
    expect(root.querySelector('.heatmap__cells')).toBeNull();
  });

  it('writes accessible tooltips with count and date', () => {
    const days = [{ date: '2025-01-01', articles: 1, comments: 0, reactions: 0, total: 1 }];
    renderHeatmap(root, { days, max: 1 });

    const cell = root.querySelector('.heatmap__cells .heatmap__cell:not(.heatmap__cell--blank)');
    expect(cell.getAttribute('title')).toContain('1 contribution');
    expect(cell.getAttribute('title')).toContain('2025');
  });
});
