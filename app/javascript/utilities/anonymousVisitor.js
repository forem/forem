/**
 * Anonymous visitor identifier and article tag history, kept in localStorage.
 *
 * This exists to serve better content to signed-out readers: a stable anonymous
 * ID plus a tally of the tags on the articles they read. Nothing here is sent
 * to the server; it stays in the visitor's browser.
 *
 * An ID is only created in regions an admin has allowed
 * (Settings::General.geos_with_allowed_anonymous_tracking). The server decides
 * that from Fastly's geolocation and tells the browser through billboard
 * responses, which carry data-anonymous-tracking-allowed="true" (see
 * BillboardsController#anonymous_tracking_allowed?). Once an ID exists it is
 * never reset: we keep reading it and keep tallying tags.
 *
 * Guidance for admins and future changes:
 * - A persistent localStorage ID counts as device storage in many places
 *   (e.g. the EU/EEA and UK under GDPR and ePrivacy) and needs prior consent
 *   there. Only allow such regions if this is first gated on the cookie banner
 *   (localStorage "cookie_status" === "allowed"), which this module doesn't do.
 * - If this data is ever sent to the server or used for ads (e.g. billboard
 *   targeting), that use must be allowed for advertising in each region and/or
 *   compatible with the cookie banner, and the privacy policy should cover it.
 * - Removing a region from the setting stops new IDs from being created, but
 *   doesn't clear existing ones. Clearing them needs a change here.
 */

export const ANONYMOUS_VISITOR_ID_KEY = 'anonymous_visitor_id';
export const ANONYMOUS_VISITOR_TAG_VIEWS_KEY = 'anonymous_visitor_tag_views';
// Keeps storage bounded; the least recently read tags are dropped first.
export const MAX_TRACKED_TAGS = 50;

function getStorage() {
  try {
    return window.localStorage || null;
  } catch (e) {
    // Accessing localStorage throws when storage is blocked.
    return null;
  }
}

function isSignedIn() {
  return document.body?.dataset.userStatus === 'logged-in';
}

function generateId() {
  const { crypto } = window;
  if (!crypto) {
    return null;
  }
  if (typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  if (typeof crypto.getRandomValues === 'function') {
    const bytes = crypto.getRandomValues(new Uint8Array(16));
    return Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join(
      '',
    );
  }
  return null;
}

/**
 * @returns {string|null} The visitor's anonymous ID, if one was created before.
 */
export function getAnonymousVisitorId() {
  try {
    return getStorage()?.getItem(ANONYMOUS_VISITOR_ID_KEY) || null;
  } catch (e) {
    return null;
  }
}

/**
 * Returns the existing anonymous ID, or creates one. Only call this once the
 * server has said the visitor's region allows it.
 *
 * @returns {string|null} The ID, or null if it couldn't be stored.
 */
export function ensureAnonymousVisitorId() {
  const existingId = getAnonymousVisitorId();
  if (existingId) {
    return existingId;
  }

  const storage = getStorage();
  const id = generateId();
  if (!storage || !id) {
    return null;
  }

  try {
    storage.setItem(ANONYMOUS_VISITOR_ID_KEY, id);
    return id;
  } catch (e) {
    return null;
  }
}

/**
 * @returns {Object<string, {count: number, lastViewedAt: number}>} Tag name to
 *   how many times it was read and when it was last read (epoch ms).
 */
export function getAnonymousVisitorTagViews() {
  try {
    const tagViews = JSON.parse(
      getStorage()?.getItem(ANONYMOUS_VISITOR_TAG_VIEWS_KEY),
    );
    return tagViews && typeof tagViews === 'object' && !Array.isArray(tagViews)
      ? tagViews
      : {};
  } catch (e) {
    return {};
  }
}

function keepMostRecentTags(tagViews) {
  const tags = Object.keys(tagViews);
  if (tags.length <= MAX_TRACKED_TAGS) {
    return tagViews;
  }

  return Object.fromEntries(
    tags
      .sort((a, b) => tagViews[b].lastViewedAt - tagViews[a].lastViewedAt)
      .slice(0, MAX_TRACKED_TAGS)
      .map((tag) => [tag, tagViews[tag]]),
  );
}

/**
 * Adds the tags of the article on the page to the visitor's tag history. Only
 * signed-out visitors who already have an anonymous ID are tracked, and each
 * article page view is counted once.
 *
 * @param {HTMLElement|null} articleContainer The #article-show-container element.
 */
export function recordAnonymousArticleTagView(articleContainer) {
  if (
    !articleContainer ||
    articleContainer.dataset.anonymousTagViewRecorded === 'true' ||
    isSignedIn() ||
    !getAnonymousVisitorId()
  ) {
    return;
  }

  const tags = (articleContainer.dataset.articleTags || '')
    .split(',')
    .map((tag) => tag.trim())
    .filter(Boolean);
  if (tags.length === 0) {
    return;
  }

  articleContainer.dataset.anonymousTagViewRecorded = 'true';
  const tagViews = getAnonymousVisitorTagViews();
  const now = Date.now();
  tags.forEach((tag) => {
    const count = Number(tagViews[tag]?.count) || 0;
    tagViews[tag] = { count: count + 1, lastViewedAt: now };
  });

  try {
    getStorage()?.setItem(
      ANONYMOUS_VISITOR_TAG_VIEWS_KEY,
      JSON.stringify(keepMostRecentTags(tagViews)),
    );
  } catch (e) {
    // Storage is full or blocked; tag history is best effort.
  }
}

/**
 * Runs after billboards render. Creates the anonymous ID when a billboard says
 * the visitor's region allows it, then records the current article's tags if
 * the visitor has an ID (whether it was just created or already existed).
 *
 * @param {ParentNode} root Where to look for rendered billboards.
 */
export function syncAnonymousVisitor(root = document) {
  if (isSignedIn()) {
    return;
  }

  if (
    root.querySelector(
      '[data-display-unit][data-anonymous-tracking-allowed="true"]',
    )
  ) {
    ensureAnonymousVisitorId();
  }

  recordAnonymousArticleTagView(
    document.getElementById('article-show-container'),
  );
}
