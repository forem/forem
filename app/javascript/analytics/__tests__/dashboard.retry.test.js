/**
 * Retry-button UX tests for the analytics dashboard error UI.
 *
 * When the bundled /api/analytics/dashboard request fails, we render a
 * user-clickable "Retry" button that re-invokes the currently-active time
 * range (week/month/infinity). An automatic 1x retry on network-level
 * TypeErrors lives in `./client`.
 */

jest.mock('@utilities/locale', () => ({
  locale: jest.fn((key, opts = {}) => {
    if (key === 'core.dashboard_analytics_avg_read_time') return `avg. read time ${opts.seconds}s`;
    if (key === 'core.dashboard_analytics_unique_reactors') return `${opts.count} unique reactors`;
    return key.split('.').pop();
  }),
}));

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

const { initCharts } = require('../dashboard');
const { callDashboardAPI } = require('../client');

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
      <div><div id="readers-card"></div></div>
      <div><div id="reactions-card"></div></div>
      <div><div id="comments-card"></div></div>
      <div><div id="bookmarks-card"></div></div>
      <div><div id="followers-card"></div></div>
    </div>
    <div class="charts-container"><div id="readers-chart"></div></div>
    <div class="charts-container"><div id="reactions-chart"></div></div>
    <div class="charts-container"><div id="comments-chart"></div></div>
    <div class="charts-container"><div id="followers-chart"></div></div>
    <div id="referrers-chart"></div>
    <table><tbody id="referrers-container"></tbody></table>
    <div id="top-contributors-container"></div>
  `;
}

// Resolve after currently-queued microtasks so rejected promises have had a
// chance to propagate through dashboard's .catch handlers.
function flushMicrotasks() {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

describe('Analytics Dashboard – error UI Retry button', () => {
  beforeEach(() => {
    window._analyticsState = { activeCharts: {}, apiGeneration: 0 };
    setupDOM();
    jest.clearAllMocks();
  });

  describe('when callDashboardAPI fails', () => {
    beforeEach(() => {
      callDashboardAPI.mockRejectedValue(new Error('boom'));
    });

    it('renders a Retry button in each chart container and the referrers container', async () => {
      initCharts({ organizationId: null, articleId: null });
      await flushMicrotasks();

      ['reactions-chart', 'comments-chart', 'readers-chart', 'followers-chart'].forEach((id) => {
        const container = document.getElementById(id);
        expect(container).not.toBeNull();
        expect(container.textContent).toContain('Failed to fetch chart data');
        expect(container.querySelector('[data-analytics-retry]')).not.toBeNull();
      });

      const referrers = document.getElementById('referrers-container');
      expect(referrers.textContent).toContain('Failed to fetch referrer data');
      expect(referrers.querySelector('[data-analytics-retry]')).not.toBeNull();
    });

    it('clicking Retry re-invokes the active range (week by default)', async () => {
      initCharts({ organizationId: null, articleId: null });
      await flushMicrotasks();

      expect(callDashboardAPI).toHaveBeenCalledTimes(1);

      const retryBtn = document
        .getElementById('reactions-chart')
        .querySelector('[data-analytics-retry]');
      expect(retryBtn).not.toBeNull();
      retryBtn.click();
      await flushMicrotasks();

      expect(callDashboardAPI).toHaveBeenCalledTimes(2);
    });

    it('clicking Retry from the referrers container re-invokes the active range', async () => {
      initCharts({ organizationId: null, articleId: null });
      await flushMicrotasks();

      expect(callDashboardAPI).toHaveBeenCalledTimes(1);

      const retryBtn = document
        .getElementById('referrers-container')
        .querySelector('[data-analytics-retry]');
      expect(retryBtn).not.toBeNull();
      retryBtn.click();
      await flushMicrotasks();

      expect(callDashboardAPI).toHaveBeenCalledTimes(2);
    });

    it('clicking Retry after switching to Infinity re-invokes Infinity range', async () => {
      initCharts({ organizationId: 42, articleId: null });
      await flushMicrotasks();

      // Switch to Infinity
      document.getElementById('infinity-button').click();
      await flushMicrotasks();

      // Most recent call should use the 2019-04-01 "beginning of time" date.
      const infinityCall = callDashboardAPI.mock.calls[callDashboardAPI.mock.calls.length - 1];
      expect(infinityCall[0].toISOString().split('T')[0]).toBe('2019-04-01');
      expect(infinityCall[1]).toEqual({ organizationId: 42, articleId: null });

      const callsBeforeRetry = callDashboardAPI.mock.calls.length;
      const retryBtn = document
        .getElementById('reactions-chart')
        .querySelector('[data-analytics-retry]');
      retryBtn.click();
      await flushMicrotasks();

      const retryCall = callDashboardAPI.mock.calls[callDashboardAPI.mock.calls.length - 1];
      expect(callDashboardAPI.mock.calls.length).toBe(callsBeforeRetry + 1);
      expect(retryCall[0].toISOString().split('T')[0]).toBe('2019-04-01');
    });
  });

  it('binds each Retry button exactly once even if showErrors runs multiple times', async () => {
    callDashboardAPI.mockRejectedValue(new Error('boom'));

    initCharts({ organizationId: null, articleId: null });
    await flushMicrotasks();

    const retryBtn = document
      .getElementById('reactions-chart')
      .querySelector('[data-analytics-retry]');

    retryBtn.click();
    await flushMicrotasks();

    // After click → second call → that call also fails → error UI re-renders.
    // The original button is replaced; the new one should be clickable.
    const newRetryBtn = document
      .getElementById('reactions-chart')
      .querySelector('[data-analytics-retry]');
    expect(newRetryBtn).not.toBeNull();
    const callsBefore = callDashboardAPI.mock.calls.length;
    newRetryBtn.click();
    await flushMicrotasks();
    expect(callDashboardAPI.mock.calls.length).toBe(callsBefore + 1);
  });
});
