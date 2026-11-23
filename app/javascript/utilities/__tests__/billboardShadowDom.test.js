import {
  mountBillboardShadowHost,
  mountBillboardShadowHosts,
  cleanupBillboardShadowHost,
  cleanupDisconnectedBillboardSandboxes,
  cleanupAllBillboardSandboxes,
  findClosestInEventPath,
  queryAllIncludingBillboardShadows,
} from '../billboardShadowDom';

function createShadowHostHtml({ id = '1', template = 'authorship_box', innerHtml = '' } = {}) {
  return `
    <div class="billboard-shadow-host"
         data-billboard-shadow-host="true"
         data-billboard-id="${id}"
         data-billboard-template="${template}">
      <template shadowrootmode="open">
        <style data-billboard-base-styles="true">:host { display: block; }</style>
        <div class="billboard-shadow-body">${innerHtml}</div>
      </template>
    </div>
  `;
}

describe('billboardShadowDom', () => {
  let consoleErrorSpy;
  let consoleWarnSpy;

  beforeEach(() => {
    jest.useFakeTimers();
    document.body.innerHTML = '';
    document.body.className = '';
    document.head.innerHTML = '<meta name="csrf-token" content="secret-csrf">';
    document.title = 'Original Forem Title';
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    cleanupAllBillboardSandboxes();
    jest.useRealTimers();
    consoleErrorSpy.mockRestore();
    consoleWarnSpy.mockRestore();
    delete window.sharedLeak;
    delete window.Forem?.revealBillboardPlacement;
    delete window.showLoginModal;
  });

  it('hydrates declarative shadow templates inserted via innerHTML and executes scripts idempotently', () => {
    document.body.innerHTML = createShadowHostHtml({
      id: '10',
      innerHtml: `
        <div id="counter">0</div>
        <script type="application/x-forem-billboard-script" data-billboard-script="true">
          const el = document.getElementById('counter');
          el.textContent = String(Number(el.textContent) + 1);
        </script>
      `,
    });

    const host = document.querySelector('[data-billboard-shadow-host="true"]');
    mountBillboardShadowHosts(document);
    mountBillboardShadowHosts(document);

    expect(host.shadowRoot).not.toBeNull();
    expect(host.querySelector('template[shadowrootmode="open"]')).toBeNull();
    expect(host.shadowRoot.getElementById('counter').textContent).toBe('1');
  });

  it('keeps the base styles as the first stylesheet so author cascade layers are ordered after the base layer', () => {
    document.body.innerHTML = `
      ${createShadowHostHtml({
        id: '11',
        innerHtml: '<style>@layer promo { p { margin: 0; } }</style><p>Hi</p>',
      })}
      <div class="billboard-shadow-host" data-billboard-shadow-host="true" data-billboard-id="12">
        <template shadowrootmode="open">
          <style data-billboard-base-styles="true">:host { display: block; }</style>
          <style>@layer promo { p { margin: 0; } }</style>
          <p>Unwrapped</p>
        </template>
      </div>
    `;

    mountBillboardShadowHosts(document);

    ['11', '12'].forEach((id) => {
      const { shadowRoot } = document.querySelector(
        `[data-billboard-id="${id}"]`,
      );
      const styles = shadowRoot.querySelectorAll('style');
      expect(shadowRoot.firstElementChild).toBe(styles[0]);
      expect(styles[0].hasAttribute('data-billboard-base-styles')).toBe(true);
      expect(styles[1].textContent).toContain('@layer promo');
      expect(
        shadowRoot.querySelector('.billboard-shadow-body p'),
      ).not.toBeNull();
    });
  });

  it('isolates DOM queries and window globals across multiple billboards and from the host page', () => {
    document.body.innerHTML = `
      <h1 id="title">Host Page Title</h1>
      ${createShadowHostHtml({
        id: '101',
        innerHtml: `
          <h1 id="title">BB 1</h1>
          <script type="application/x-forem-billboard-script" data-billboard-script="true">
            window.sharedLeak = 'from-bb-1';
            document.getElementById('title').textContent = 'Updated by ' + window.sharedLeak;
          </script>
          <script type="application/x-forem-billboard-script" data-billboard-script="true">
            document.getElementById('title').dataset.fromSecondScript = window.sharedLeak;
          </script>
        `,
      })}
      ${createShadowHostHtml({
        id: '102',
        innerHtml: `
          <h1 id="title">BB 2</h1>
          <script type="application/x-forem-billboard-script" data-billboard-script="true">
            window.sharedLeak = 'from-bb-2';
            document.getElementById('title').textContent = 'Updated by ' + window.sharedLeak;
          </script>
        `,
      })}
    `;

    mountBillboardShadowHosts(document);

    const hosts = document.querySelectorAll('[data-billboard-shadow-host="true"]');
    expect(document.getElementById('title').textContent).toBe('Host Page Title');
    expect(window.sharedLeak).toBeUndefined();

    expect(hosts[0].shadowRoot.getElementById('title').textContent).toBe('Updated by from-bb-1');
    expect(hosts[0].shadowRoot.getElementById('title').dataset.fromSecondScript).toBe('from-bb-1');
    expect(hosts[1].shadowRoot.getElementById('title').textContent).toBe('Updated by from-bb-2');
  });

  it('redirects document.head style writes into shadowRoot, preserves meta reads, and blocks document.write and document.title', () => {
    document.body.innerHTML = createShadowHostHtml({
      id: '20',
      innerHtml: `
        <div id="meta-out"></div>
        <script type="application/x-forem-billboard-script" data-billboard-script="true">
          const style = document.createElement('style');
          style.textContent = '.scoped { color: green; }';
          document.head.appendChild(style);
          document.write('<p>wipe</p>');
          document.title = 'Hijacked Title';
          const csrf = document.head.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
          document.getElementById('meta-out').textContent = csrf || 'missing';
        </script>
      `,
    });

    const host = document.querySelector('[data-billboard-shadow-host="true"]');
    mountBillboardShadowHost(host);

    expect(document.head.querySelectorAll('style').length).toBe(0);
    expect(host.shadowRoot.querySelectorAll('style').length).toBe(2);
    expect(host.shadowRoot.getElementById('meta-out').textContent).toBe('secret-csrf');
    expect(document.title).toBe('Original Forem Title');
    expect(consoleWarnSpy).toHaveBeenCalledWith(expect.stringContaining('Blocked document.write()'));
  });

  it('allows site-wide Forem APIs and standard built-ins inside the sandbox', () => {
    const revealSpy = jest.fn();
    const loginSpy = jest.fn();
    window.Forem = { ...(window.Forem || {}), revealBillboardPlacement: revealSpy };
    window.showLoginModal = loginSpy;

    document.body.innerHTML = createShadowHostHtml({
      id: '30',
      innerHtml: `
        <div id="url-host"></div>
        <script type="application/x-forem-billboard-script" data-billboard-script="true">
          window.Forem.revealBillboardPlacement('post_sidebar');
          window.showLoginModal({ trigger: 'billboard' });
          const parsed = new URL('https://dev.to/events/test');
          document.getElementById('url-host').textContent = parsed.hostname;
        </script>
      `,
    });

    const host = document.querySelector('[data-billboard-shadow-host="true"]');
    mountBillboardShadowHost(host);

    expect(revealSpy).toHaveBeenCalledWith('post_sidebar');
    expect(loginSpy).toHaveBeenCalledWith({ trigger: 'billboard' });
    expect(host.shadowRoot.getElementById('url-host').textContent).toBe('dev.to');
  });

  it('contains runtime and syntax errors without crashing sibling billboards', () => {
    document.body.innerHTML = `
      ${createShadowHostHtml({
        id: '40',
        innerHtml: `
          <script type="application/x-forem-billboard-script" data-billboard-script="true">
            throw new Error('broken billboard');
          </script>
        `,
      })}
      ${createShadowHostHtml({
        id: '41',
        innerHtml: `
          <div id="ok">pending</div>
          <script type="application/x-forem-billboard-script" data-billboard-script="true">
            document.getElementById('ok').textContent = 'healthy';
          </script>
        `,
      })}
    `;

    expect(() => mountBillboardShadowHosts(document)).not.toThrow();
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      '[Billboard 40] script execution error:',
      expect.any(Error),
    );

    const hosts = document.querySelectorAll('[data-billboard-shadow-host="true"]');
    expect(hosts[1].shadowRoot.getElementById('ok').textContent).toBe('healthy');
  });

  it('automatically cleans up intervals, timeouts, listeners, abort signals, and cleanup callbacks on unmount', () => {
    const resizeSpy = jest.fn();
    window.__resizeCheck = resizeSpy;

    document.body.innerHTML = createShadowHostHtml({
      id: '50',
      innerHtml: `
        <div id="ticks">0</div>
        <div id="cleaned">no</div>
        <script type="application/x-forem-billboard-script" data-billboard-script="true">
          let ticks = 0;
          setInterval(() => {
            ticks += 1;
            document.getElementById('ticks').textContent = String(ticks);
          }, 1000);
          setTimeout(() => {
            document.getElementById('ticks').dataset.timedOut = 'yes';
          }, 5000);
          window.addEventListener('resize', () => {
            window.__resizeCheck();
          });
          billboard.onCleanup(() => {
            document.getElementById('cleaned').textContent = 'yes';
          });
          billboard.signal.addEventListener('abort', () => {
            document.getElementById('cleaned').dataset.aborted = 'true';
          });
        </script>
      `,
    });

    const host = document.querySelector('[data-billboard-shadow-host="true"]');
    mountBillboardShadowHost(host);

    jest.advanceTimersByTime(2000);
    window.dispatchEvent(new Event('resize'));

    expect(host.shadowRoot.getElementById('ticks').textContent).toBe('2');
    expect(resizeSpy).toHaveBeenCalledTimes(1);

    // Simulate InstantClick detaching the page content and sweeping disconnected sandboxes
    host.remove();
    cleanupDisconnectedBillboardSandboxes();

    jest.advanceTimersByTime(10000);
    window.dispatchEvent(new Event('resize'));

    expect(host.shadowRoot.getElementById('ticks').textContent).toBe('2');
    expect(host.shadowRoot.getElementById('ticks').dataset.timedOut).toBeUndefined();
    expect(resizeSpy).toHaveBeenCalledTimes(1);
    expect(host.shadowRoot.getElementById('cleaned').textContent).toBe('yes');
    expect(host.shadowRoot.getElementById('cleaned').dataset.aborted).toBe('true');

    // Simulate InstantClick history restore re-attaching the host
    document.body.appendChild(host);
    mountBillboardShadowHosts(document);
    jest.advanceTimersByTime(1000);
    expect(host.shadowRoot.getElementById('ticks').textContent).toBe('1');

    delete window.__resizeCheck;
  });

  it('mirrors dark-theme state onto the shadow host and inner body wrapper', async () => {
    document.body.classList.add('dark-theme');
    document.body.innerHTML = createShadowHostHtml({
      id: '60',
      innerHtml: '<p>Themed</p>',
    });

    const host = document.querySelector('[data-billboard-shadow-host="true"]');
    mountBillboardShadowHost(host);

    const shadowBody = host.shadowRoot.querySelector('.billboard-shadow-body');
    expect(host.classList.contains('dark-theme')).toBe(true);
    expect(host.dataset.theme).toBe('dark');
    expect(shadowBody.classList.contains('dark-theme')).toBe(true);

    document.body.classList.remove('dark-theme');
    await Promise.resolve();

    expect(host.classList.contains('dark-theme')).toBe(false);
    expect(host.dataset.theme).toBe('light');
    expect(shadowBody.classList.contains('dark-theme')).toBe(false);
  });

  it('runs a LiveStream-style countdown script cleanly inside Shadow DOM and swaps in iframe at target time', () => {
    const startTimeIso = new Date(Date.now() + 2000).toISOString();
    document.body.innerHTML = createShadowHostHtml({
      id: '70',
      innerHtml: `
        <div class="overlay-feed" id="overlay-feed-9">
          <div id="countdown-feed-9">--:--:--</div>
        </div>
        <div class="player-container-feed" id="player-container-feed-9"></div>
        <script type="application/x-forem-billboard-script" data-billboard-script="true">
          (function() {
            const TARGET_TIME = new Date(${JSON.stringify(startTimeIso)}).getTime();
            function update() {
              const overlay = document.getElementById("overlay-feed-9");
              const countdownEl = document.getElementById("countdown-feed-9");
              const playerContainer = document.getElementById("player-container-feed-9");
              const now = Date.now();
              if (now >= TARGET_TIME) {
                if (window.liveStreamIntervals && window.liveStreamIntervals["9"]) {
                  clearInterval(window.liveStreamIntervals["9"]);
                  delete window.liveStreamIntervals["9"];
                }
                if (overlay) overlay.classList.remove("active");
                if (playerContainer && !playerContainer.querySelector("iframe")) {
                  const iframe = document.createElement("iframe");
                  iframe.src = "https://www.youtube.com/embed/abc";
                  playerContainer.appendChild(iframe);
                }
                return;
              }
              if (overlay) overlay.classList.add("active");
              if (countdownEl) {
                const diffSeconds = Math.max(0, Math.floor((TARGET_TIME - now) / 1000));
                countdownEl.textContent = "00:00:0" + diffSeconds;
              }
            }
            window.liveStreamIntervals = window.liveStreamIntervals || {};
            window.liveStreamIntervals["9"] = setInterval(update, 1000);
            update();
          })();
        </script>
      `,
    });

    const host = document.querySelector('[data-billboard-shadow-host="true"]');
    mountBillboardShadowHost(host);

    expect(window.liveStreamIntervals).toBeUndefined();
    expect(host.shadowRoot.getElementById('overlay-feed-9').classList.contains('active')).toBe(true);
    expect(host.shadowRoot.getElementById('countdown-feed-9').textContent).toBe('00:00:02');

    jest.advanceTimersByTime(2000);

    expect(host.shadowRoot.getElementById('overlay-feed-9').classList.contains('active')).toBe(false);
    const iframe = host.shadowRoot.querySelector('#player-container-feed-9 iframe');
    expect(iframe).not.toBeNull();
    expect(iframe.src).toContain('youtube.com/embed/abc');

    cleanupBillboardShadowHost(host);
  });

  it('finds elements and event targets across open billboard shadow roots', () => {
    document.body.innerHTML = `
      <div id="outer">
        <button data-event-signup-button="true" id="light-btn">Light</button>
        ${createShadowHostHtml({
          id: '80',
          innerHtml: `
            <a href="/events/demo" id="shadow-link"><span>Watch</span></a>
            <button data-event-signup-button="true" id="shadow-btn">Shadow</button>
          `,
        })}
      </div>
    `;

    const host = document.querySelector('[data-billboard-shadow-host="true"]');
    mountBillboardShadowHost(host);

    const buttons = queryAllIncludingBillboardShadows('[data-event-signup-button="true"]');
    expect(buttons.map((b) => b.id)).toEqual(['light-btn', 'shadow-btn']);

    let foundLink = null;
    document.getElementById('outer').addEventListener('click', (event) => {
      foundLink = findClosestInEventPath(event, 'a');
    });

    const innerSpan = host.shadowRoot.querySelector('#shadow-link span');
    innerSpan.dispatchEvent(new MouseEvent('click', { bubbles: true, composed: true }));

    expect(foundLink).toBe(host.shadowRoot.getElementById('shadow-link'));
  });
});
