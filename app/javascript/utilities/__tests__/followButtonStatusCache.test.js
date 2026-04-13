import {
  FOLLOW_BUTTON_STATUS_CACHE_KEY,
  MAX_CACHED_FOLLOW_BUTTON_STATUSES,
  getCachedFollowButtonStatus,
  removeCachedFollowButtonStatus,
  syncCachedFollowButtonStatus,
} from '../followButtonStatusCache';

const buildButtonInfo = (id, className = 'User') => ({
  id,
  className,
});

describe('followButtonStatusCache', () => {
  beforeEach(() => {
    window.localStorage.clear();
    jest.useFakeTimers().setSystemTime(new Date('2026-04-13T00:00:00.000Z'));
  });

  afterEach(() => {
    jest.useRealTimers();
    window.localStorage.clear();
  });

  it('stores only cacheable follow statuses and removes default follow states', () => {
    const buttonInfo = buildButtonInfo(1);

    syncCachedFollowButtonStatus(buttonInfo, 'follow-back');
    expect(getCachedFollowButtonStatus(buttonInfo)).toBe('follow-back');

    syncCachedFollowButtonStatus(buttonInfo, 'false');
    expect(getCachedFollowButtonStatus(buttonInfo)).toBeNull();
    expect(window.localStorage.getItem(FOLLOW_BUTTON_STATUS_CACHE_KEY)).toBeNull();
  });

  it('removes malformed cache payloads instead of reusing them', () => {
    const buttonInfo = buildButtonInfo(2);

    window.localStorage.setItem(FOLLOW_BUTTON_STATUS_CACHE_KEY, '{invalid-json');

    expect(getCachedFollowButtonStatus(buttonInfo)).toBeNull();
    expect(window.localStorage.getItem(FOLLOW_BUTTON_STATUS_CACHE_KEY)).toBeNull();
  });

  it('keeps only the most recent 1000 cached results', () => {
    Array.from(
      { length: MAX_CACHED_FOLLOW_BUTTON_STATUSES + 5 },
      (_, index) => index + 1,
    ).forEach((id) => {
      jest.setSystemTime(new Date(1_000 * id));
      syncCachedFollowButtonStatus(buildButtonInfo(id), 'self');
    });

    const storedCache = JSON.parse(
      window.localStorage.getItem(FOLLOW_BUTTON_STATUS_CACHE_KEY),
    );

    expect(Object.keys(storedCache)).toHaveLength(
      MAX_CACHED_FOLLOW_BUTTON_STATUSES,
    );
    expect(storedCache['User:1']).toBeUndefined();
    expect(storedCache[`User:${MAX_CACHED_FOLLOW_BUTTON_STATUSES + 5}`].status).toBe(
      'self',
    );
  });

  it('can explicitly remove a cached follow status', () => {
    const buttonInfo = buildButtonInfo(3, 'Organization');

    syncCachedFollowButtonStatus(buttonInfo, 'true');
    removeCachedFollowButtonStatus(buttonInfo);

    expect(getCachedFollowButtonStatus(buttonInfo)).toBeNull();
  });
});
