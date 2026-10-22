import { webcrypto } from 'crypto';
import {
  ANONYMOUS_VISITOR_ID_KEY,
  ANONYMOUS_VISITOR_TAG_VIEWS_KEY,
  MAX_TRACKED_TAGS,
  ensureAnonymousVisitorId,
  getAnonymousVisitorId,
  getAnonymousVisitorTagViews,
  recordAnonymousArticleTagView,
  syncAnonymousVisitor,
} from '@utilities/anonymousVisitor';

function renderPage({ allowed, tags = 'javascript,webdev', signedIn = false }) {
  document.body.dataset.userStatus = signedIn ? 'logged-in' : 'logged-out';
  document.body.innerHTML = `
    <article id="article-show-container" data-article-tags="${tags}"></article>
    <div class="js-billboard" data-display-unit data-viewer-country="US"
      ${allowed ? 'data-anonymous-tracking-allowed="true"' : ''}></div>
  `;
}

function articleContainer() {
  return document.getElementById('article-show-container');
}

describe('anonymousVisitor', () => {
  beforeEach(() => {
    // jsdom doesn't provide Web Crypto, which every supported browser has.
    Object.defineProperty(window, 'crypto', {
      value: webcrypto,
      configurable: true,
    });
    localStorage.clear();
    delete document.body.dataset.userStatus;
    document.body.innerHTML = '';
  });

  describe('syncAnonymousVisitor', () => {
    it('creates an ID and records the article tags when a billboard allows it', () => {
      renderPage({ allowed: true });

      syncAnonymousVisitor();

      expect(getAnonymousVisitorId()).toEqual(expect.any(String));
      const tagViews = getAnonymousVisitorTagViews();
      expect(Object.keys(tagViews)).toEqual(['javascript', 'webdev']);
      expect(tagViews.javascript.count).toBe(1);
    });

    it('does nothing when no billboard allows it and there is no ID yet', () => {
      renderPage({ allowed: false });

      syncAnonymousVisitor();

      expect(localStorage.getItem(ANONYMOUS_VISITOR_ID_KEY)).toBeNull();
      expect(localStorage.getItem(ANONYMOUS_VISITOR_TAG_VIEWS_KEY)).toBeNull();
    });

    it('keeps an existing ID and keeps recording tags without a billboard allowing it', () => {
      localStorage.setItem(ANONYMOUS_VISITOR_ID_KEY, 'existing-id');
      renderPage({ allowed: false });

      syncAnonymousVisitor();

      expect(getAnonymousVisitorId()).toBe('existing-id');
      expect(getAnonymousVisitorTagViews().webdev.count).toBe(1);
    });

    it('never resets an existing ID when a billboard allows tracking again', () => {
      localStorage.setItem(ANONYMOUS_VISITOR_ID_KEY, 'existing-id');
      renderPage({ allowed: true });

      syncAnonymousVisitor();

      expect(getAnonymousVisitorId()).toBe('existing-id');
    });

    it('does nothing for signed-in users', () => {
      renderPage({ allowed: true, signedIn: true });

      syncAnonymousVisitor();

      expect(localStorage.getItem(ANONYMOUS_VISITOR_ID_KEY)).toBeNull();
      expect(localStorage.getItem(ANONYMOUS_VISITOR_TAG_VIEWS_KEY)).toBeNull();
    });

    it('counts each article page view once', () => {
      renderPage({ allowed: true });

      syncAnonymousVisitor();
      syncAnonymousVisitor();

      expect(getAnonymousVisitorTagViews().javascript.count).toBe(1);
    });
  });

  describe('ensureAnonymousVisitorId', () => {
    it('returns the same ID on every call', () => {
      const id = ensureAnonymousVisitorId();

      expect(id).toEqual(expect.any(String));
      expect(id.length).toBeGreaterThanOrEqual(32);
      expect(ensureAnonymousVisitorId()).toBe(id);
    });

    it('falls back to getRandomValues without randomUUID', () => {
      Object.defineProperty(window, 'crypto', {
        value: { getRandomValues: (array) => webcrypto.getRandomValues(array) },
        configurable: true,
      });

      expect(ensureAnonymousVisitorId()).toMatch(/^[0-9a-f]{32}$/);
    });

    it('does not create an ID without Web Crypto', () => {
      Object.defineProperty(window, 'crypto', {
        value: undefined,
        configurable: true,
      });

      expect(ensureAnonymousVisitorId()).toBeNull();
      expect(localStorage.getItem(ANONYMOUS_VISITOR_ID_KEY)).toBeNull();
    });
  });

  describe('recordAnonymousArticleTagView', () => {
    beforeEach(() => {
      localStorage.setItem(ANONYMOUS_VISITOR_ID_KEY, 'existing-id');
    });

    it('adds to the counts of tags read before', () => {
      renderPage({ allowed: false, tags: 'javascript' });
      recordAnonymousArticleTagView(articleContainer());
      renderPage({ allowed: false, tags: 'javascript,react' });
      recordAnonymousArticleTagView(articleContainer());

      const tagViews = getAnonymousVisitorTagViews();
      expect(tagViews.javascript.count).toBe(2);
      expect(tagViews.react.count).toBe(1);
    });

    it('drops the least recently read tags beyond the limit', () => {
      const oldTagViews = {};
      for (let i = 0; i < MAX_TRACKED_TAGS; i += 1) {
        oldTagViews[`tag${i}`] = { count: 5, lastViewedAt: i };
      }
      localStorage.setItem(
        ANONYMOUS_VISITOR_TAG_VIEWS_KEY,
        JSON.stringify(oldTagViews),
      );
      renderPage({ allowed: false, tags: 'newtag' });

      recordAnonymousArticleTagView(articleContainer());

      const tagViews = getAnonymousVisitorTagViews();
      expect(Object.keys(tagViews)).toHaveLength(MAX_TRACKED_TAGS);
      expect(tagViews.newtag.count).toBe(1);
      expect(tagViews.tag0).toBeUndefined();
      expect(tagViews.tag1).toBeDefined();
    });

    it('recovers from unreadable stored tag history', () => {
      localStorage.setItem(ANONYMOUS_VISITOR_TAG_VIEWS_KEY, '{not json');
      renderPage({ allowed: false, tags: 'javascript' });

      recordAnonymousArticleTagView(articleContainer());

      expect(getAnonymousVisitorTagViews().javascript.count).toBe(1);
    });

    it('ignores articles without tags', () => {
      renderPage({ allowed: false, tags: '' });

      recordAnonymousArticleTagView(articleContainer());

      expect(localStorage.getItem(ANONYMOUS_VISITOR_TAG_VIEWS_KEY)).toBeNull();
    });
  });
});
