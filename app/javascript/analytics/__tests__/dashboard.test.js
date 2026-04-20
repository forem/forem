import { initCharts } from '../dashboard';

// Mock locale utility
jest.mock('@utilities/locale', () => ({
  locale: jest.fn((key, opts = {}) => {
    if (key === 'core.dashboard_analytics_avg_read_time') return `avg. read time ${opts.seconds}s`;
    if (key === 'core.dashboard_analytics_unique_reactors') return `${opts.count} unique reactors`;
    return key.split('.').pop();
  }),
}));

// Capture ApexCharts constructor calls
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

jest.mock('../client', () => ({
  callHistoricalAPI: jest.fn(),
  callTotalsAPI: jest.fn(),
  callReferrersAPI: jest.fn(),
  callTopContributorsAPI: jest.fn(),
  callFollowerEngagementAPI: jest.fn(),
}));

// Build sample historical data spanning 120 days
function buildHistoricalData(days) {
  const data = {};
  const now = new Date();
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(d.getDate() - i);
    const key = d.toISOString().split('T')[0];
    data[key] = {
      comments: { total: Math.floor(Math.random() * 5) },
      reactions: {
        total: 5, like: 3, readinglist: 1, unicorn: 1,
        exploding_head: 0, raised_hands: 0, fire: 0,
      },
      page_views: { total: 50 + i, average_read_time_in_seconds: 30 },
      follows: { total: i % 10 === 0 ? 1 : 0 },
    };
  }
  return data;
}

const mockHistoricalData = buildHistoricalData(120);
const mockTotalsData = {
  comments: { total: 50 },
  reactions: { total: 100, like: 60, readinglist: 10, unicorn: 20, exploding_head: 5, raised_hands: 3, fire: 2, unique_reactors: 25 },
  page_views: { total: 5000, average_read_time_in_seconds: 35 },
  follows: { total: 15 },
};
const mockReferrersData = { domains: [{ domain: 'google.com', count: 100 }] };
const mockTopContributorsData = [
  { user_id: 1, username: 'alice', name: 'Alice', profile_image: '/img/alice.png', reactions_count: 5, comments_count: 2, score: 11 },
  { user_id: 2, username: 'bob', name: 'Bob', profile_image: '/img/bob.png', reactions_count: 3, comments_count: 0, score: 3 },
];
const mockFollowerEngagementData = { total_followers: 200, engaged_followers: 30, ratio: 15.0 };

function setupDOM() {
  document.body.innerHTML = `
    <div class="crayons-tabs crayons-tabs--analytics">
      <ul class="crayons-tabs__list">
        <li><button class="crayons-tabs__item crayons-tabs__item--current" id="week-button" aria-current="page">Week</button></li>
        <li><button class="crayons-tabs__item" id="month-button">Month</button></li>
        <li><button class="crayons-tabs__item" id="infinity-button">Infinity</button></li>
      </ul>
    </div>
    <div class="summary-stats">
      <div><div id="readers-card" class="py-3"><div class="analytics-loading crayons-scaffold-loading"></div></div></div>
      <div><div id="reactions-card" class="py-3"><div class="analytics-loading crayons-scaffold-loading"></div></div></div>
      <div><div id="comments-card" class="py-3"><div class="analytics-loading crayons-scaffold-loading"></div></div></div>
      <div><div id="bookmarks-card" class="py-3"><div class="analytics-loading crayons-scaffold-loading"></div></div></div>
      <div><div id="followers-card" class="py-3"><div class="analytics-loading crayons-scaffold-loading"></div></div></div>
    </div>
    <div class="charts-container"><div id="readers-chart"><div class="analytics-loading crayons-scaffold-loading"></div></div></div>
    <div class="charts-container"><div id="reactions-chart"><div class="analytics-loading crayons-scaffold-loading"></div></div></div>
    <div class="charts-container"><div id="comments-chart"><div class="analytics-loading crayons-scaffold-loading"></div></div></div>
    <div class="charts-container"><div id="followers-chart"><div class="analytics-loading crayons-scaffold-loading"></div></div></div>
    <div id="referrers-chart"><div class="analytics-loading crayons-scaffold-loading"></div></div>
    <table><tbody id="referrers-container"></tbody></table>
    <div id="top-contributors-container"><div class="analytics-loading crayons-scaffold-loading"></div></div>
  `;
}

describe('Analytics Dashboard – Brush/Zoom for Infinity', () => {
  const { callHistoricalAPI, callTotalsAPI, callReferrersAPI, callTopContributorsAPI, callFollowerEngagementAPI } = require('../client');

  beforeEach(() => {
    // Reset shared window state between tests
    window._analyticsState = { activeCharts: {}, apiGeneration: 0 };
    setupDOM();
    MockApexCharts.mockClear();
    mockRender.mockClear();
    mockDestroy.mockClear();
    callHistoricalAPI.mockResolvedValue(mockHistoricalData);
    callTotalsAPI.mockResolvedValue(mockTotalsData);
    callReferrersAPI.mockResolvedValue(mockReferrersData);
    callTopContributorsAPI.mockResolvedValue(mockTopContributorsData);
    callFollowerEngagementAPI.mockResolvedValue(mockFollowerEngagementData);
  });

  async function flushPromises() {
    await new Promise((resolve) => setTimeout(resolve, 0));
    await new Promise((resolve) => setTimeout(resolve, 0));
  }

  test('week/month charts use category x-axis without brush', async () => {
    initCharts({});
    await flushPromises();

    // 4 main charts (readers, reactions, comments, followers) + 1 donut (referrers)
    const calls = MockApexCharts.mock.calls;
    const mainChartCalls = calls.filter(([, opts]) => opts.chart.type !== 'donut');

    mainChartCalls.forEach(([, opts]) => {
      // Should use categories, not datetime
      expect(opts.xaxis.type).toBeUndefined();
      expect(opts.xaxis.categories).toBeDefined();
      // Should not have brush config
      expect(opts.chart.brush).toBeUndefined();
      // Zoom should be disabled
      expect(opts.chart.zoom.enabled).toBe(false);
    });

    // No brush divs should exist
    expect(document.getElementById('brush-readers-chart')).toBeNull();
    expect(document.getElementById('brush-reactions-chart')).toBeNull();
    expect(document.getElementById('brush-comments-chart')).toBeNull();
    expect(document.getElementById('brush-followers-chart')).toBeNull();
  });

  test('infinity charts use datetime x-axis with brush navigators', async () => {
    initCharts({});
    await flushPromises();
    MockApexCharts.mockClear();

    // Click infinity button
    document.getElementById('infinity-button').click();
    await flushPromises();

    const calls = MockApexCharts.mock.calls;

    // Find main chart calls (have chart.id starting with 'main-')
    const mainCalls = calls.filter(([, opts]) => opts.chart.id && opts.chart.id.startsWith('main-'));
    // Find brush chart calls (have chart.brush.enabled)
    const brushCalls = calls.filter(([, opts]) => opts.chart.brush && opts.chart.brush.enabled);

    // Should have 4 main charts and 4 brush charts
    expect(mainCalls.length).toBe(4);
    expect(brushCalls.length).toBe(4);

    // Main charts should use datetime x-axis with initial zoom range
    mainCalls.forEach(([, opts]) => {
      expect(opts.xaxis.type).toBe('datetime');
      expect(opts.xaxis.min).toBeDefined();
      expect(opts.xaxis.max).toBeDefined();
      expect(opts.chart.zoom.enabled).toBe(true);
      expect(opts.chart.toolbar.show).toBe(true);
    });

    // Brush charts should target correct main charts
    const brushTargets = brushCalls.map(([, opts]) => opts.chart.brush.target).sort();
    expect(brushTargets).toEqual([
      'main-comments-chart',
      'main-followers-chart',
      'main-reactions-chart',
      'main-readers-chart',
    ]);

    // Brush charts should have datetime x-axis
    brushCalls.forEach(([, opts]) => {
      expect(opts.xaxis.type).toBe('datetime');
      expect(opts.chart.selection.enabled).toBe(true);
    });

    // Brush divs should exist in DOM
    expect(document.getElementById('brush-readers-chart')).not.toBeNull();
    expect(document.getElementById('brush-reactions-chart')).not.toBeNull();
    expect(document.getElementById('brush-comments-chart')).not.toBeNull();
    expect(document.getElementById('brush-followers-chart')).not.toBeNull();
  });

  test('brush selection defaults to last 90 days of data', async () => {
    initCharts({});
    await flushPromises();
    MockApexCharts.mockClear();

    document.getElementById('infinity-button').click();
    await flushPromises();

    const brushCalls = MockApexCharts.mock.calls.filter(
      ([, opts]) => opts.chart.brush && opts.chart.brush.enabled,
    );

    const labels = Object.keys(mockHistoricalData);
    const lastTimestamp = new Date(labels[labels.length - 1]).getTime();
    const ninetyDaysMs = 90 * 24 * 60 * 60 * 1000;
    const expectedMin = lastTimestamp - ninetyDaysMs;

    brushCalls.forEach(([, opts]) => {
      const { min, max } = opts.chart.selection.xaxis;
      // Selection max should be the last data point
      expect(max).toBe(lastTimestamp);
      // Selection min should be ~90 days before the last data point
      // (may be clamped to first data point if data < 90 days)
      const firstTimestamp = new Date(labels[0]).getTime();
      expect(min).toBe(Math.max(firstTimestamp, expectedMin));
    });
  });

  test('infinity series data uses [timestamp, value] pairs', async () => {
    initCharts({});
    await flushPromises();
    MockApexCharts.mockClear();

    document.getElementById('infinity-button').click();
    await flushPromises();

    const mainCalls = MockApexCharts.mock.calls.filter(
      ([, opts]) => opts.chart.id && opts.chart.id.startsWith('main-'),
    );

    mainCalls.forEach(([, opts]) => {
      opts.series.forEach((s) => {
        s.data.forEach((point) => {
          // Each data point should be a [timestamp, value] pair
          expect(Array.isArray(point)).toBe(true);
          expect(point.length).toBe(2);
          expect(typeof point[0]).toBe('number'); // timestamp
          expect(typeof point[1]).toBe('number'); // value
        });
      });
    });
  });

  test('switching from infinity back to week cleans up brush charts', async () => {
    initCharts({});
    await flushPromises();

    // Switch to infinity
    document.getElementById('infinity-button').click();
    await flushPromises();

    // Brush divs should exist
    expect(document.getElementById('brush-readers-chart')).not.toBeNull();

    // Switch back to week
    document.getElementById('week-button').click();
    await flushPromises();

    // Brush divs should be removed
    expect(document.getElementById('brush-readers-chart')).toBeNull();
    expect(document.getElementById('brush-reactions-chart')).toBeNull();
    expect(document.getElementById('brush-comments-chart')).toBeNull();
    expect(document.getElementById('brush-followers-chart')).toBeNull();
  });
});

describe('Analytics Dashboard – Async Chart Loading', () => {
  const { callHistoricalAPI, callTotalsAPI, callReferrersAPI, callTopContributorsAPI, callFollowerEngagementAPI } = require('../client');

  beforeEach(() => {
    // Reset shared window state between tests
    window._analyticsState = { activeCharts: {}, apiGeneration: 0 };
    setupDOM();
    MockApexCharts.mockClear();
    mockRender.mockClear();
    mockDestroy.mockClear();
    callTopContributorsAPI.mockResolvedValue([]);
    callFollowerEngagementAPI.mockResolvedValue({ total_followers: 0, engaged_followers: 0, ratio: 0.0 });
  });

  async function flushPromises() {
    await new Promise((resolve) => setTimeout(resolve, 0));
    await new Promise((resolve) => setTimeout(resolve, 0));
  }

  test('charts render when historical resolves even if totals is still pending', async () => {
    let resolveTotals;
    const totalsPromise = new Promise((resolve) => { resolveTotals = resolve; });
    callHistoricalAPI.mockResolvedValue(mockHistoricalData);
    callTotalsAPI.mockReturnValue(totalsPromise);
    callReferrersAPI.mockResolvedValue(mockReferrersData);

    initCharts({});
    await flushPromises();

    // Charts should be rendered (from historical)
    const chartCalls = MockApexCharts.mock.calls.filter(([, opts]) => opts.chart.type !== 'donut');
    expect(chartCalls.length).toBeGreaterThan(0);

    // Cards should show data (from historical, without totals)
    expect(document.getElementById('readers-card').innerHTML).not.toContain('analytics-loading');

    // Now resolve totals — cards should update with extra info
    resolveTotals(mockTotalsData);
    await flushPromises();

    expect(document.getElementById('reactions-card').innerHTML).toContain('unique reactors');
  });

  test('referrers load independently of historical and totals', async () => {
    let resolveHistorical;
    const historicalPromise = new Promise((resolve) => { resolveHistorical = resolve; });
    callHistoricalAPI.mockReturnValue(historicalPromise);
    callTotalsAPI.mockResolvedValue(mockTotalsData);
    callReferrersAPI.mockResolvedValue(mockReferrersData);

    initCharts({});
    await flushPromises();

    // Referrers should be rendered even though historical hasn't resolved
    const referrersContainer = document.getElementById('referrers-container');
    expect(referrersContainer.innerHTML).toContain('google.com');

    // Charts should NOT be rendered yet
    const chartCalls = MockApexCharts.mock.calls.filter(([, opts]) => opts.chart.type !== 'donut');
    // Only the donut chart should exist at this point
    const donutCalls = MockApexCharts.mock.calls.filter(([, opts]) => opts.chart.type === 'donut');
    expect(donutCalls.length).toBe(1);

    // Now resolve historical — charts appear
    resolveHistorical(mockHistoricalData);
    await flushPromises();

    const allChartCalls = MockApexCharts.mock.calls.filter(([, opts]) => opts.chart.type !== 'donut');
    expect(allChartCalls.length).toBeGreaterThan(0);
  });

  test('loading placeholders are shown before data arrives', async () => {
    let resolveHistorical;
    const historicalPromise = new Promise((resolve) => { resolveHistorical = resolve; });
    callHistoricalAPI.mockReturnValue(historicalPromise);
    callTotalsAPI.mockReturnValue(new Promise(() => {}));
    callReferrersAPI.mockReturnValue(new Promise(() => {}));

    initCharts({});
    // Don't flush — let promises stay pending

    // Placeholders should be visible in chart containers
    expect(document.getElementById('readers-chart').querySelector('.analytics-loading')).not.toBeNull();
    expect(document.getElementById('reactions-chart').querySelector('.analytics-loading')).not.toBeNull();

    // Resolve historical to clear chart placeholders
    resolveHistorical(mockHistoricalData);
    await flushPromises();

    // Chart containers should no longer have placeholders (replaced by ApexCharts)
    // The innerHTML is cleared by drawChart before rendering
    expect(document.getElementById('readers-chart').querySelector('.analytics-loading')).toBeNull();
  });

  test('chart errors do not prevent referrer rendering', async () => {
    callHistoricalAPI.mockRejectedValue(new Error('API error'));
    callTotalsAPI.mockRejectedValue(new Error('API error'));
    callReferrersAPI.mockResolvedValue(mockReferrersData);
    callTopContributorsAPI.mockResolvedValue([]);

    initCharts({});
    await flushPromises();

    // Referrers should still render
    const referrersContainer = document.getElementById('referrers-container');
    expect(referrersContainer.innerHTML).toContain('google.com');
  });

  test('top contributors panel renders async with ranked list', async () => {
    callHistoricalAPI.mockResolvedValue(mockHistoricalData);
    callTotalsAPI.mockResolvedValue(mockTotalsData);
    callReferrersAPI.mockResolvedValue(mockReferrersData);
    callTopContributorsAPI.mockResolvedValue(mockTopContributorsData);

    initCharts({});
    await flushPromises();

    const container = document.getElementById('top-contributors-container');
    expect(container.innerHTML).toContain('alice');
    expect(container.innerHTML).toContain('bob');
    // Alice should appear before Bob (higher score)
    expect(container.innerHTML.indexOf('alice')).toBeLessThan(container.innerHTML.indexOf('bob'));
  });

  test('top contributors shows empty message when no data', async () => {
    callTopContributorsAPI.mockResolvedValue([]);

    initCharts({});
    await flushPromises();

    const container = document.getElementById('top-contributors-container');
    expect(container.innerHTML).toContain('top_contributors_empty');
  });

  test('stale top contributors response is discarded after navigation', async () => {
    callHistoricalAPI.mockResolvedValue(mockHistoricalData);
    callTotalsAPI.mockResolvedValue(mockTotalsData);
    callReferrersAPI.mockResolvedValue(mockReferrersData);

    let resolveContributors;
    callTopContributorsAPI.mockReturnValue(new Promise((r) => { resolveContributors = r; }));

    initCharts({});
    // Simulate navigation — call initCharts again which bumps generation
    callTopContributorsAPI.mockResolvedValue([]);
    initCharts({});

    resolveContributors(mockTopContributorsData);
    await flushPromises();

    const container = document.getElementById('top-contributors-container');
    // Should NOT have rendered the stale data — only the empty message from the second call
    expect(container.innerHTML).not.toContain('alice');
  });

  test('follower engagement ratio renders on followers card', async () => {
    callHistoricalAPI.mockResolvedValue(mockHistoricalData);
    callTotalsAPI.mockResolvedValue(mockTotalsData);
    callReferrersAPI.mockResolvedValue(mockReferrersData);
    callFollowerEngagementAPI.mockResolvedValue(mockFollowerEngagementData);

    initCharts({});
    await flushPromises();

    const card = document.getElementById('followers-card');
    const engagement = card.querySelector('.follower-engagement');
    expect(engagement).not.toBeNull();
    expect(engagement.textContent).toContain('follower_engagement_ratio');
  });

  test('follower engagement does not render when no followers', async () => {
    callHistoricalAPI.mockResolvedValue(mockHistoricalData);
    callTotalsAPI.mockResolvedValue(mockTotalsData);
    callReferrersAPI.mockResolvedValue(mockReferrersData);
    callFollowerEngagementAPI.mockResolvedValue({ total_followers: 0, engaged_followers: 0, ratio: 0.0 });

    initCharts({});
    await flushPromises();

    const card = document.getElementById('followers-card');
    expect(card.querySelector('.follower-engagement')).toBeNull();
  });

  test('charts show empty state message when historical data is empty', async () => {
    callHistoricalAPI.mockResolvedValue({});
    callTotalsAPI.mockResolvedValue({
      comments: { total: 0 },
      reactions: { total: 0, like: 0, readinglist: 0, unicorn: 0, exploding_head: 0, raised_hands: 0, fire: 0, unique_reactors: 0 },
      page_views: { total: 0, average_read_time_in_seconds: 0 },
      follows: { total: 0 },
    });
    callReferrersAPI.mockResolvedValue({ domains: [] });

    initCharts({});
    await flushPromises();

    ['readers-chart', 'reactions-chart', 'comments-chart', 'followers-chart'].forEach((id) => {
      const el = document.getElementById(id);
      expect(el.innerHTML).toContain('dashboard_analytics_no_data');
    });

    // No ApexCharts instances should be created for main charts
    const mainChartCalls = MockApexCharts.mock.calls.filter(([, opts]) => opts.chart.type !== 'donut');
    expect(mainChartCalls.length).toBe(0);
  });

  test('referrers show empty state when no domains', async () => {
    callHistoricalAPI.mockResolvedValue(mockHistoricalData);
    callTotalsAPI.mockResolvedValue(mockTotalsData);
    callReferrersAPI.mockResolvedValue({ domains: [] });

    initCharts({});
    await flushPromises();

    const container = document.getElementById('referrers-container');
    expect(container.innerHTML).toContain('dashboard_analytics_no_referrers');

    // Referrer chart should be cleared, no donut rendered
    const donutCalls = MockApexCharts.mock.calls.filter(([, opts]) => opts.chart.type === 'donut');
    expect(donutCalls.length).toBe(0);
  });

  test('cards show zero values when data is empty', async () => {
    callHistoricalAPI.mockResolvedValue({});
    callTotalsAPI.mockResolvedValue({
      comments: { total: 0 },
      reactions: { total: 0, like: 0, readinglist: 0, unicorn: 0, exploding_head: 0, raised_hands: 0, fire: 0, unique_reactors: 0 },
      page_views: { total: 0, average_read_time_in_seconds: 0 },
      follows: { total: 0 },
    });
    callReferrersAPI.mockResolvedValue({ domains: [] });

    initCharts({});
    await flushPromises();

    const readersCard = document.getElementById('readers-card');
    expect(readersCard.innerHTML).toContain('0');

    const reactionsCard = document.getElementById('reactions-card');
    expect(reactionsCard.innerHTML).toContain('0');

    const commentsCard = document.getElementById('comments-card');
    expect(commentsCard.innerHTML).toContain('0');
  });
});
