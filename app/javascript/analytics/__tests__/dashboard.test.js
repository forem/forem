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
  callDashboardAPI: jest.fn(),
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

function bundle(overrides = {}) {
  return {
    historical: mockHistoricalData,
    totals: mockTotalsData,
    referrers: mockReferrersData,
    top_contributors: mockTopContributorsData,
    follower_engagement: mockFollowerEngagementData,
    ...overrides,
  };
}

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

async function flushPromises() {
  await new Promise((resolve) => setTimeout(resolve, 0));
  await new Promise((resolve) => setTimeout(resolve, 0));
}

describe('Analytics Dashboard – Brush/Zoom for Infinity', () => {
  const { callDashboardAPI } = require('../client');

  beforeEach(() => {
    window._analyticsState = { activeCharts: {}, apiGeneration: 0 };
    setupDOM();
    MockApexCharts.mockClear();
    mockRender.mockClear();
    mockDestroy.mockClear();
    callDashboardAPI.mockResolvedValue(bundle());
  });

  test('week/month charts use category x-axis without brush', async () => {
    initCharts({});
    await flushPromises();

    const calls = MockApexCharts.mock.calls;
    const mainChartCalls = calls.filter(([, opts]) => opts.chart.type !== 'donut');

    mainChartCalls.forEach(([, opts]) => {
      expect(opts.xaxis.type).toBeUndefined();
      expect(opts.xaxis.categories).toBeDefined();
      expect(opts.chart.brush).toBeUndefined();
      expect(opts.chart.zoom.enabled).toBe(false);
    });

    expect(document.getElementById('brush-readers-chart')).toBeNull();
    expect(document.getElementById('brush-reactions-chart')).toBeNull();
    expect(document.getElementById('brush-comments-chart')).toBeNull();
    expect(document.getElementById('brush-followers-chart')).toBeNull();
  });

  test('infinity charts use datetime x-axis with brush navigators', async () => {
    initCharts({});
    await flushPromises();
    MockApexCharts.mockClear();

    document.getElementById('infinity-button').click();
    await flushPromises();

    const calls = MockApexCharts.mock.calls;
    const mainCalls = calls.filter(([, opts]) => opts.chart.id && opts.chart.id.startsWith('main-'));
    const brushCalls = calls.filter(([, opts]) => opts.chart.brush && opts.chart.brush.enabled);

    expect(mainCalls.length).toBe(4);
    expect(brushCalls.length).toBe(4);

    mainCalls.forEach(([, opts]) => {
      expect(opts.xaxis.type).toBe('datetime');
      expect(opts.xaxis.min).toBeDefined();
      expect(opts.xaxis.max).toBeDefined();
      expect(opts.chart.zoom.enabled).toBe(true);
      expect(opts.chart.toolbar.show).toBe(true);
    });

    const brushTargets = brushCalls.map(([, opts]) => opts.chart.brush.target).sort();
    expect(brushTargets).toEqual([
      'main-comments-chart',
      'main-followers-chart',
      'main-reactions-chart',
      'main-readers-chart',
    ]);

    brushCalls.forEach(([, opts]) => {
      expect(opts.xaxis.type).toBe('datetime');
      expect(opts.chart.selection.enabled).toBe(true);
    });

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
      expect(max).toBe(lastTimestamp);
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
          expect(Array.isArray(point)).toBe(true);
          expect(point.length).toBe(2);
          expect(typeof point[0]).toBe('number');
          expect(typeof point[1]).toBe('number');
        });
      });
    });
  });

  test('switching from infinity back to week cleans up brush charts', async () => {
    initCharts({});
    await flushPromises();

    document.getElementById('infinity-button').click();
    await flushPromises();

    expect(document.getElementById('brush-readers-chart')).not.toBeNull();

    document.getElementById('week-button').click();
    await flushPromises();

    expect(document.getElementById('brush-readers-chart')).toBeNull();
    expect(document.getElementById('brush-reactions-chart')).toBeNull();
    expect(document.getElementById('brush-comments-chart')).toBeNull();
    expect(document.getElementById('brush-followers-chart')).toBeNull();
  });
});

describe('Analytics Dashboard – Bundled Endpoint Rendering', () => {
  const { callDashboardAPI } = require('../client');

  beforeEach(() => {
    window._analyticsState = { activeCharts: {}, apiGeneration: 0 };
    setupDOM();
    MockApexCharts.mockClear();
    mockRender.mockClear();
    mockDestroy.mockClear();
    callDashboardAPI.mockReset();
  });

  test('issues exactly ONE dashboard API call per initCharts', async () => {
    callDashboardAPI.mockResolvedValue(bundle());

    initCharts({});
    await flushPromises();

    expect(callDashboardAPI).toHaveBeenCalledTimes(1);
  });

  test('renders cards, charts, referrers, top contributors, and followers from single response', async () => {
    callDashboardAPI.mockResolvedValue(bundle());

    initCharts({});
    await flushPromises();

    // Cards populated (no more loading placeholders)
    expect(document.getElementById('readers-card').innerHTML).not.toContain('analytics-loading');
    expect(document.getElementById('reactions-card').innerHTML).toContain('unique reactors');

    // Referrers rendered
    const referrersContainer = document.getElementById('referrers-container');
    expect(referrersContainer.innerHTML).toContain('google.com');

    // Top contributors rendered
    const topContribContainer = document.getElementById('top-contributors-container');
    expect(topContribContainer.innerHTML).toContain('alice');
    expect(topContribContainer.innerHTML).toContain('bob');
    expect(topContribContainer.innerHTML.indexOf('alice')).toBeLessThan(topContribContainer.innerHTML.indexOf('bob'));

    // Follower engagement rendered
    const followerCard = document.getElementById('followers-card');
    expect(followerCard.querySelector('.follower-engagement')).not.toBeNull();

    // Charts rendered
    const chartCalls = MockApexCharts.mock.calls.filter(([, opts]) => opts.chart.type !== 'donut');
    expect(chartCalls.length).toBeGreaterThan(0);
  });

  test('loading placeholders are shown before data arrives', async () => {
    let resolve;
    callDashboardAPI.mockReturnValue(new Promise((r) => { resolve = r; }));

    initCharts({});
    // Don't flush — promise stays pending

    expect(document.getElementById('readers-chart').querySelector('.analytics-loading')).not.toBeNull();
    expect(document.getElementById('reactions-chart').querySelector('.analytics-loading')).not.toBeNull();

    resolve(bundle());
    await flushPromises();

    expect(document.getElementById('readers-chart').querySelector('.analytics-loading')).toBeNull();
  });

  test('shows error UI on both charts and referrers when the request fails', async () => {
    callDashboardAPI.mockRejectedValue(new Error('boom'));

    initCharts({});
    await flushPromises();

    ['readers-chart', 'reactions-chart', 'comments-chart', 'followers-chart'].forEach((id) => {
      const el = document.getElementById(id);
      expect(el.textContent).toContain('Failed to fetch chart data');
    });

    const referrersContainer = document.getElementById('referrers-container');
    expect(referrersContainer.textContent).toContain('Failed to fetch referrer data');
  });

  test('top contributors shows empty message when no data', async () => {
    callDashboardAPI.mockResolvedValue(bundle({ top_contributors: [] }));

    initCharts({});
    await flushPromises();

    const container = document.getElementById('top-contributors-container');
    expect(container.innerHTML).toContain('top_contributors_empty');
  });

  test('stale response is discarded after navigation', async () => {
    let resolveStale;
    callDashboardAPI
      .mockReturnValueOnce(new Promise((r) => { resolveStale = r; }))
      .mockResolvedValueOnce(bundle({ top_contributors: [] }));

    initCharts({});
    // Simulate navigation — second initCharts bumps generation
    initCharts({});
    await flushPromises();

    // Resolve the first (stale) call after navigation — it must be ignored
    resolveStale(bundle());
    await flushPromises();

    const container = document.getElementById('top-contributors-container');
    expect(container.innerHTML).not.toContain('alice');
  });

  test('follower engagement ratio renders on followers card', async () => {
    callDashboardAPI.mockResolvedValue(bundle());

    initCharts({});
    await flushPromises();

    const card = document.getElementById('followers-card');
    const engagement = card.querySelector('.follower-engagement');
    expect(engagement).not.toBeNull();
    expect(engagement.textContent).toContain('follower_engagement_ratio');
  });

  test('follower engagement does not render when no followers', async () => {
    callDashboardAPI.mockResolvedValue(bundle({
      follower_engagement: { total_followers: 0, engaged_followers: 0, ratio: 0.0 },
    }));

    initCharts({});
    await flushPromises();

    const card = document.getElementById('followers-card');
    expect(card.querySelector('.follower-engagement')).toBeNull();
  });

  test('charts show empty state message when historical data is empty', async () => {
    callDashboardAPI.mockResolvedValue(bundle({
      historical: {},
      totals: {
        comments: { total: 0 },
        reactions: { total: 0, like: 0, readinglist: 0, unicorn: 0, exploding_head: 0, raised_hands: 0, fire: 0, unique_reactors: 0 },
        page_views: { total: 0, average_read_time_in_seconds: 0 },
        follows: { total: 0 },
      },
      referrers: { domains: [] },
    }));

    initCharts({});
    await flushPromises();

    ['readers-chart', 'reactions-chart', 'comments-chart', 'followers-chart'].forEach((id) => {
      const el = document.getElementById(id);
      expect(el.innerHTML).toContain('dashboard_analytics_no_data');
    });

    const mainChartCalls = MockApexCharts.mock.calls.filter(([, opts]) => opts.chart.type !== 'donut');
    expect(mainChartCalls.length).toBe(0);
  });

  test('referrers show empty state when no domains', async () => {
    callDashboardAPI.mockResolvedValue(bundle({ referrers: { domains: [] } }));

    initCharts({});
    await flushPromises();

    const container = document.getElementById('referrers-container');
    expect(container.innerHTML).toContain('dashboard_analytics_no_referrers');

    const donutCalls = MockApexCharts.mock.calls.filter(([, opts]) => opts.chart.type === 'donut');
    expect(donutCalls.length).toBe(0);
  });

  test('cards show zero values when data is empty', async () => {
    callDashboardAPI.mockResolvedValue(bundle({
      historical: {},
      totals: {
        comments: { total: 0 },
        reactions: { total: 0, like: 0, readinglist: 0, unicorn: 0, exploding_head: 0, raised_hands: 0, fire: 0, unique_reactors: 0 },
        page_views: { total: 0, average_read_time_in_seconds: 0 },
        follows: { total: 0 },
      },
      referrers: { domains: [] },
    }));

    initCharts({});
    await flushPromises();

    expect(document.getElementById('readers-card').innerHTML).toContain('0');
    expect(document.getElementById('reactions-card').innerHTML).toContain('0');
    expect(document.getElementById('comments-card').innerHTML).toContain('0');
  });
});
