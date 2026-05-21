import { renderHeatmap, __testing__ } from '../heatmap';

const { buildSeries, colorRanges, computeStreaks, findBestDay, tooltipHTML } = __testing__;

// Capture ApexCharts constructor calls so we can assert renderHeatmap
// hands off the right configuration without bringing in the real library.
const mockRender = jest.fn().mockResolvedValue(undefined);
const mockDestroy = jest.fn();
const MockApexCharts = jest.fn().mockImplementation(() => ({
  render: mockRender,
  destroy: mockDestroy,
}));

jest.mock('apexcharts', () => ({
  __esModule: true,
  default: MockApexCharts,
}));

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

describe('heatmap helpers', () => {
  describe('buildSeries', () => {
    it('produces 7 series of equal length aligned to the leading weekday', () => {
      const days = makeDays(7);
      const { series, xLabels } = buildSeries(days);

      expect(series).toHaveLength(7);
      // Jan 1 2025 is Wednesday (UTC dow=3) so the first observed day lands
      // in column 0 row 3; the row contains 7 days → 2 columns total
      // (one for the partial leading week, one for the trailing days).
      expect(xLabels).toHaveLength(2);
      series.forEach((row) => {
        expect(row.data).toHaveLength(2);
      });
      // Sunday row (0) has no real data in either column.
      expect(series[0].data.every((p) => p.y === 0)).toBe(true);
      // The anchor Sunday should precede the first observed Wednesday.
      expect(xLabels[0]).toBe('2024-12-29');
    });

    it('returns empty series for an empty payload', () => {
      expect(buildSeries([])).toEqual({ series: [], dayLookup: {} });
    });
  });

  describe('colorRanges', () => {
    it('returns just the empty bucket when max is zero', () => {
      const ranges = colorRanges(0);
      expect(ranges).toHaveLength(1);
      expect(ranges[0].name).toBe('0');
    });

    it('produces a five-bucket scale for max > 1', () => {
      const ranges = colorRanges(10);
      expect(ranges).toHaveLength(5);
      // Buckets must be strictly non-overlapping and monotonically increasing.
      for (let i = 1; i < ranges.length; i += 1) {
        expect(ranges[i].from).toBeGreaterThanOrEqual(ranges[i - 1].to);
      }
    });
  });

  describe('computeStreaks', () => {
    it('counts the current streak from the end and the longest run anywhere', () => {
      const days = [
        { total: 1 }, { total: 1 }, { total: 0 },
        { total: 1 }, { total: 1 }, { total: 1 },
      ];
      expect(computeStreaks(days)).toEqual({ current: 3, longest: 3 });
    });
  });

  describe('findBestDay', () => {
    it('returns the day with the highest total', () => {
      const days = [
        { date: '2025-01-01', total: 1 },
        { date: '2025-01-02', total: 9 },
        { date: '2025-01-03', total: 4 },
      ];
      expect(findBestDay(days).date).toBe('2025-01-02');
    });
  });

  describe('tooltipHTML', () => {
    const labels = {
      noActivityLabel: 'No activity yet',
      articlesLabel: 'Articles',
      commentsLabel: 'Comments',
      reactionsLabel: 'Reactions',
      contributionLabel: 'contribution',
      contributionsLabel: 'contributions',
    };

    it('renders an empty-state title when no day is supplied', () => {
      expect(tooltipHTML(null, labels)).toContain('No activity yet');
    });

    it('renders the per-day breakdown and pluralizes correctly', () => {
      const html = tooltipHTML(
        { date: '2025-01-01', articles: 1, comments: 2, reactions: 3, total: 6 },
        labels,
      );
      expect(html).toContain('6 contributions');
      expect(html).toContain('Articles');
      expect(html).toContain('>1<');
      expect(html).toContain('>2<');
      expect(html).toContain('>3<');
    });
  });
});

describe('renderHeatmap', () => {
  let root;

  beforeEach(() => {
    jest.clearAllMocks();
    root = document.createElement('div');
    root.id = 'dashboard-heatmap';
    document.body.appendChild(root);
  });

  afterEach(() => {
    root.remove();
  });

  it('renders the empty-state copy when there are no days', () => {
    renderHeatmap(root, { days: [], max: 0 }, { emptyLabel: 'Nothing yet' });
    expect(root.textContent).toContain('Nothing yet');
    expect(MockApexCharts).not.toHaveBeenCalled();
  });

  it('renders stats cards from totals and the days array', async () => {
    const wrapper = document.createElement('div');
    const stats = document.createElement('div');
    stats.setAttribute('data-heatmap-stats', '');
    wrapper.appendChild(stats);
    wrapper.appendChild(root);
    document.body.appendChild(wrapper);

    const days = makeDays(7, (i) => (i === 3 ? 5 : 0));
    renderHeatmap(
      root,
      { days, max: 5, totals: { total: 5, articles: 1, comments: 2, reactions: 2 } },
      { wrapperEl: wrapper, totalLabel: 'Total' },
    );

    expect(stats.querySelectorAll('.heatmap-stat')).toHaveLength(4);
    expect(stats.textContent).toContain('Total');
    wrapper.remove();
  });

  it('instantiates ApexCharts with a heatmap chart type and 7 series', async () => {
    const days = makeDays(7, (i) => i);
    renderHeatmap(root, { days, max: 6 });

    // Dynamic import resolves on a microtask; flush before asserting.
    await Promise.resolve();
    await Promise.resolve();

    expect(MockApexCharts).toHaveBeenCalledTimes(1);
    const [container, opts] = MockApexCharts.mock.calls[0];
    expect(container).toBe(root);
    expect(opts.chart.type).toBe('heatmap');
    expect(opts.series).toHaveLength(7);
    expect(mockRender).toHaveBeenCalled();
  });

  it('destroys the prior chart before re-rendering into the same container', async () => {
    const days = makeDays(7, (i) => i);
    renderHeatmap(root, { days, max: 6 });
    await Promise.resolve();
    await Promise.resolve();

    renderHeatmap(root, { days, max: 6 });
    await Promise.resolve();
    await Promise.resolve();

    expect(mockDestroy).toHaveBeenCalled();
    expect(MockApexCharts).toHaveBeenCalledTimes(2);
  });

  it('pins the side panel when a cell is selected and clears on Escape', async () => {
    const wrapper = document.createElement('div');
    const panel = document.createElement('aside');
    panel.setAttribute('data-heatmap-detail', '');
    wrapper.appendChild(panel);
    wrapper.appendChild(root);
    document.body.appendChild(wrapper);

    const days = makeDays(7, (i) => (i === 3 ? 9 : 0));
    renderHeatmap(root, { days, max: 9 }, {
      wrapperEl: wrapper,
      detailHintLabel: 'Click any day',
      pinnedLabel: 'Pinned',
      contributionLabel: 'contribution',
      contributionsLabel: 'contributions',
      articlesLabel: 'Articles',
      commentsLabel: 'Comments',
      reactionsLabel: 'Reactions',
    });

    // Default seed: the busiest day (index 3 = Jan 4 2025) appears unpinned.
    expect(panel.dataset.pinned).toBe('false');
    expect(panel.textContent).toContain('9 contributions');

    // The ApexCharts constructor is called after the dynamic import resolves.
    await Promise.resolve();
    await Promise.resolve();

    // Simulate the ApexCharts click callback for a different day.
    const opts = MockApexCharts.mock.calls[0][1];
    opts.chart.events.click(null, null, { seriesIndex: 3, dataPointIndex: 0 });
    expect(panel.dataset.pinned).toBe('true');
    expect(panel.textContent).toContain('Pinned');
    expect(panel.textContent).toContain('2025');

    // Esc clears the pin.
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
    expect(panel.dataset.pinned).toBe('false');

    wrapper.remove();
  });
});
