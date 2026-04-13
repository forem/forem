const FOLLOW_BUTTON_STATUS_CACHE_KEY = 'follow_button_status_cache_v1';
const MAX_CACHED_FOLLOW_BUTTON_STATUSES = 1000;
const CACHEABLE_FOLLOW_BUTTON_STATUSES = new Set([
  'true',
  'mutual',
  'follow-back',
  'self',
]);

function getLocalStorage() {
  if (typeof window === 'undefined') {
    return null;
  }

  try {
    return window.localStorage;
  } catch {
    return null;
  }
}

function normalizeCacheEntry(entry) {
  if (!entry || typeof entry !== 'object') {
    return null;
  }

  if (!CACHEABLE_FOLLOW_BUTTON_STATUSES.has(entry.status)) {
    return null;
  }

  return {
    status: entry.status,
    updatedAt: Number.isFinite(entry.updatedAt) ? entry.updatedAt : 0,
  };
}

export function readCachedFollowButtonStatuses(storage = getLocalStorage()) {
  if (!storage) {
    return {};
  }

  try {
    const rawCache = storage.getItem(FOLLOW_BUTTON_STATUS_CACHE_KEY);

    if (!rawCache) {
      return {};
    }

    const parsedCache = JSON.parse(rawCache);

    if (!parsedCache || typeof parsedCache !== 'object' || Array.isArray(parsedCache)) {
      storage.removeItem(FOLLOW_BUTTON_STATUS_CACHE_KEY);
      return {};
    }

    return Object.entries(parsedCache).reduce((cache, [key, value]) => {
      const normalizedEntry = normalizeCacheEntry(value);

      if (normalizedEntry) {
        cache[key] = normalizedEntry;
      }

      return cache;
    }, {});
  } catch {
    storage.removeItem(FOLLOW_BUTTON_STATUS_CACHE_KEY);
    return {};
  }
}

function persistCachedFollowButtonStatuses(
  cache,
  storage = getLocalStorage(),
) {
  if (!storage) {
    return;
  }

  try {
    if (Object.keys(cache).length === 0) {
      storage.removeItem(FOLLOW_BUTTON_STATUS_CACHE_KEY);
      return;
    }

    storage.setItem(FOLLOW_BUTTON_STATUS_CACHE_KEY, JSON.stringify(cache));
  } catch {
    // Ignore localStorage write failures and fall back to the network response.
  }
}

function trimCachedFollowButtonStatuses(cache) {
  if (Object.keys(cache).length <= MAX_CACHED_FOLLOW_BUTTON_STATUSES) {
    return cache;
  }

  const trimmedEntries = Object.entries(cache)
    .sort(([, left], [, right]) => right.updatedAt - left.updatedAt)
    .slice(0, MAX_CACHED_FOLLOW_BUTTON_STATUSES);

  return Object.fromEntries(trimmedEntries);
}

function getFollowButtonStatusCacheKey({ className, id }) {
  if (!className || id === undefined || id === null) {
    return null;
  }

  return `${className}:${id}`;
}

export function getCachedFollowButtonStatus(buttonInfo, cache) {
  const cacheKey = getFollowButtonStatusCacheKey(buttonInfo);

  if (!cacheKey) {
    return null;
  }

  const cachedStatuses = cache || readCachedFollowButtonStatuses();

  return cachedStatuses[cacheKey]?.status || null;
}

export function syncCachedFollowButtonStatus(buttonInfo, followStatus) {
  const cacheKey = getFollowButtonStatusCacheKey(buttonInfo);

  if (!cacheKey) {
    return;
  }

  const cachedStatuses = readCachedFollowButtonStatuses();

  if (!CACHEABLE_FOLLOW_BUTTON_STATUSES.has(followStatus)) {
    if (cachedStatuses[cacheKey]) {
      delete cachedStatuses[cacheKey];
      persistCachedFollowButtonStatuses(cachedStatuses);
    }
    return;
  }

  cachedStatuses[cacheKey] = {
    status: followStatus,
    updatedAt: Date.now(),
  };

  persistCachedFollowButtonStatuses(
    trimCachedFollowButtonStatuses(cachedStatuses),
  );
}

/**
 * Batched version of syncCachedFollowButtonStatus that reads and writes
 * localStorage only once for a set of id → status pairs.
 *
 * @param {string} followableType The className of the followable (e.g. 'User')
 * @param {Object} idStatuses A hash of { id: followStatus } pairs
 */
export function syncBulkCachedFollowButtonStatuses(followableType, idStatuses) {
  const cachedStatuses = readCachedFollowButtonStatuses();
  let dirty = false;

  Object.keys(idStatuses).forEach((id) => {
    const cacheKey = getFollowButtonStatusCacheKey({ className: followableType, id });

    if (!cacheKey) {
      return;
    }

    const followStatus = idStatuses[id];

    if (!CACHEABLE_FOLLOW_BUTTON_STATUSES.has(followStatus)) {
      if (cachedStatuses[cacheKey]) {
        delete cachedStatuses[cacheKey];
        dirty = true;
      }
      return;
    }

    cachedStatuses[cacheKey] = {
      status: followStatus,
      updatedAt: Date.now(),
    };
    dirty = true;
  });

  if (dirty) {
    persistCachedFollowButtonStatuses(
      trimCachedFollowButtonStatuses(cachedStatuses),
    );
  }
}

export function removeCachedFollowButtonStatus(buttonInfo) {
  const cacheKey = getFollowButtonStatusCacheKey(buttonInfo);

  if (!cacheKey) {
    return;
  }

  const cachedStatuses = readCachedFollowButtonStatuses();

  if (!cachedStatuses[cacheKey]) {
    return;
  }

  delete cachedStatuses[cacheKey];
  persistCachedFollowButtonStatuses(cachedStatuses);
}

export {
  CACHEABLE_FOLLOW_BUTTON_STATUSES,
  FOLLOW_BUTTON_STATUS_CACHE_KEY,
  MAX_CACHED_FOLLOW_BUTTON_STATUSES,
  readCachedFollowButtonStatuses,
};
