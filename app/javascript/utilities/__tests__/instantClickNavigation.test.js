import fs from 'fs';
import path from 'path';

describe('InstantClick navigation & history restoration (base.js.erb)', () => {
  let xhrInstances;
  let OriginalXMLHttpRequest;
  let originalAddEventListener;
  let originalWindowAddEventListener;
  let originalPushState;
  let originalReplaceState;
  let registeredWindowListeners;

  function loadInstantClickFromBase() {
    const baseSource = fs
      .readFileSync(
        path.resolve(__dirname, '../../../assets/javascripts/base.js.erb'),
        'utf8',
      )
      .replace(/^\/\/=.*$/gm, '')
      .replace(
        /<%= javascript_path 'lib\/pulltorefresh\.js' %>/g,
        '/assets/pulltorefresh.js',
      )
      .replace(/<%= Rails\.env %>/g, 'production');

    // Run in window scope the same way Sprockets serves base.js
    // eslint-disable-next-line no-new-func
    const fn = new Function(baseSource);
    fn.call(window);
  }

  function simulateBrowserLocationPop(targetUrl) {
    originalReplaceState.call(window.history, null, '', targetUrl);
    window.dispatchEvent(new PopStateEvent('popstate'));
  }

  beforeEach(() => {
    xhrInstances = [];
    registeredWindowListeners = [];
    OriginalXMLHttpRequest = window.XMLHttpRequest;
    originalAddEventListener = EventTarget.prototype.addEventListener;
    originalWindowAddEventListener = window.addEventListener;
    originalPushState = window.history.pushState;
    originalReplaceState = window.history.replaceState;

    window.addEventListener = function trackWindowListener(
      type,
      listener,
      options,
    ) {
      registeredWindowListeners.push({ type, listener, options });
      return originalWindowAddEventListener.call(
        window,
        type,
        listener,
        options,
      );
    };

    window.initializePage = jest.fn();
    window.getImageForLink = jest.fn();
    window.PullToRefresh = { init: jest.fn() };
    window.ahoy = { configure: jest.fn() };
    window.scrollTo = jest.fn();
    delete window._instantClickHistoryHooked;
    delete window.InstantClick;
    delete window.instantClick;
    delete window.Honeybadger;
    delete window.__shellScriptRuns;
    delete window.__topBarRuns;
    delete window.__pageScriptRuns;
    delete window.__softNavSpy;

    class MockXHR {
      constructor() {
        this.readyState = 0;
        this.status = 0;
        this.responseText = '';
        this.listeners = {};
        this.aborted = false;
        xhrInstances.push(this);
      }

      addEventListener(type, cb) {
        this.listeners[type] = this.listeners[type] || [];
        this.listeners[type].push(cb);
      }

      open(method, url) {
        this.method = method;
        this.url = url;
      }

      send() {
        this.sent = true;
      }

      abort() {
        this.aborted = true;
        this.status = 0;
      }

      // eslint-disable-next-line class-methods-use-this
      getResponseHeader(name) {
        if (name === 'Content-Type') {
          return 'text/html; charset=utf-8';
        }
        return null;
      }

      respondWith(status, html) {
        this.status = status;
        this.responseText = html;
        this.readyState = 4;
        (this.listeners.readystatechange || []).forEach((cb) => cb.call(this));
        if (typeof this.onreadystatechange === 'function') {
          this.onreadystatechange();
        }
      }
    }

    window.XMLHttpRequest = MockXHR;

    window.history.replaceState(null, '', 'http://localhost/');
    document.title = 'Home';
    document.head.innerHTML = '';
    document.body.className = '';
    document.body.dataset.locale = 'en';
    document.body.innerHTML = `
      <div id="navigation-progress"></div>
      <script data-no-instant>
        window.__shellScriptRuns = (window.__shellScriptRuns || 0) + 1;
      </script>
      <script>
        window.__topBarRuns = (window.__topBarRuns || 0) + 1;
      </script>
      <div id="page-content" data-current-page="stories-index">
        <div id="page-route-change"></div>
        <a id="article-link" href="http://localhost/alice/post-1">Read Post</a>
        <div id="i18n-translations" data-translations="{}"></div>
      </div>
    `;
  });

  afterEach(() => {
    registeredWindowListeners.forEach(({ type, listener, options }) => {
      window.removeEventListener(type, listener, options);
    });
    window.XMLHttpRequest = OriginalXMLHttpRequest;
    EventTarget.prototype.addEventListener = originalAddEventListener;
    window.addEventListener = originalWindowAddEventListener;
    window.history.pushState = originalPushState;
    window.history.replaceState = originalReplaceState;
    delete window.PullToRefresh;
  });

  it('does not attach duplicate body click listeners when EventTarget.prototype.addEventListener is wrapped later (e.g. by Honeybadger)', () => {
    loadInstantClickFromBase();

    // Simulate @honeybadger-io/js wrapping EventTarget.prototype.addEventListener after initial boot
    EventTarget.prototype.addEventListener = function wrappedAddEventListener(
      type,
      listener,
      ...rest
    ) {
      const wrapped =
        typeof listener === 'function'
          ? function hbWrapped(...args) {
              return listener.apply(this, args);
            }
          : listener;
      return originalAddEventListener.call(this, type, wrapped, ...rest);
    };

    const pushStateSpy = jest.spyOn(window.history, 'pushState');

    // Navigate 1: hover preload -> click /alice/post-1
    const link1 = document.getElementById('article-link');
    link1.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));
    xhrInstances[0].respondWith(
      200,
      `<!DOCTYPE html><html><head><title>Post 1</title></head><body>
        <div id="page-content" data-current-page="stories-show">
          <div id="page-route-change"></div>
          <script type="application/ld+json">{"@type":"Article"}</script>
          <script>window.__pageScriptRuns = (window.__pageScriptRuns || 0) + 1;</script>
          <a id="next-link" href="http://localhost/bob/post-2">Next Post</a>
        </div>
      </body></html>`,
    );

    link1.dispatchEvent(
      new MouseEvent('click', { bubbles: true, cancelable: true, which: 1 }),
    );
    expect(window.location.pathname).toBe('/alice/post-1');
    expect(pushStateSpy).toHaveBeenCalledTimes(1);
    expect(window.__pageScriptRuns).toBe(1);
    // Shell data-no-instant script did NOT re-run
    expect(window.__shellScriptRuns).toBeUndefined();
    // Non-data-no-instant shell script ran once on transition
    expect(window.__topBarRuns).toBe(1);

    // Navigate 2 (after wrapped addEventListener would previously have attached a second clickListener!):
    const link2 = document.getElementById('next-link');
    link2.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));
    xhrInstances[0].respondWith(
      200,
      `<!DOCTYPE html><html><head><title>Post 2</title></head><body>
        <div id="page-content" data-current-page="stories-show">
          <div id="page-route-change"></div>
          <h1>Post 2</h1>
        </div>
      </body></html>`,
    );

    link2.dispatchEvent(
      new MouseEvent('click', { bubbles: true, cancelable: true, which: 1 }),
    );

    // Must pushState ONLY ONCE for the second navigation (total 2, not 3!)
    expect(pushStateSpy).toHaveBeenCalledTimes(2);
    expect(window.location.pathname).toBe('/bob/post-2');

    // Simulate browser Back button (popstate -> /alice/post-1)
    const restoreCallback = jest.fn();
    window.InstantClick.on('restore', restoreCallback);
    simulateBrowserLocationPop('http://localhost/alice/post-1');

    expect(restoreCallback).toHaveBeenCalledTimes(1);
    expect(document.title).toBe('Post 1');
    expect(document.getElementById('next-link')).not.toBeNull();
  });

  it('does not re-execute #page-content scripts when popstate restores a soft-navigation URL sharing the same #page-content node', () => {
    loadInstantClickFromBase();

    const pageScriptSpy = jest.fn();
    window.__softNavSpy = pageScriptSpy;
    const inlineScript = document.createElement('script');
    inlineScript.textContent = 'window.__softNavSpy();';
    document.getElementById('page-content').appendChild(inlineScript);
    expect(pageScriptSpy).toHaveBeenCalledTimes(1);

    // Simulate feed tab soft navigation (/ -> /following) via history.pushState
    window.history.pushState({}, '', '/following');
    expect(window.location.pathname).toBe('/following');

    const restoreSpy = jest.fn();
    window.InstantClick.on('restore', restoreSpy);

    // Simulate browser Back (/following -> /)
    simulateBrowserLocationPop('http://localhost/');

    expect(restoreSpy).toHaveBeenCalledTimes(1);
    // Same #page-content node stayed mounted; inline script was NOT torn out and re-executed
    expect(pageScriptSpy).toHaveBeenCalledTimes(1);
  });

  it('aborts an in-flight preload XHR on popstate so slow preloads cannot hijack back navigation', () => {
    loadInstantClickFromBase();

    const link = document.getElementById('article-link');
    link.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));
    expect(xhrInstances[0].sent).toBe(true);
    expect(xhrInstances[0].aborted).toBe(false);

    // Soft-push a state and then pop back while preload is in flight
    window.history.pushState({}, '', '/following');
    simulateBrowserLocationPop('http://localhost/');

    expect(xhrInstances[0].aborted).toBe(true);
  });
});
