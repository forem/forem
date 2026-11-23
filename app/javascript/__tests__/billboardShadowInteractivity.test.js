import {
  executeBBScripts,
  observeBillboards,
} from '../packs/billboardAfterRenderActions';
import { cleanupAllBillboardSandboxes } from '../utilities/billboardShadowDom';
import { shouldLoadEventSignupButtons } from '../utilities/eventSignupButtonsLoader';

describe('Billboard Shadow DOM site-wide interactivity', () => {
  let originalFetch;
  let originalIntersectionObserver;

  beforeEach(() => {
    originalFetch = global.fetch;
    originalIntersectionObserver = global.IntersectionObserver;

    global.fetch = jest.fn(() =>
      Promise.resolve({ ok: true, json: () => Promise.resolve({ id: 1 }) }),
    );
    global.IntersectionObserver = class {
      observe() {}
      unobserve() {}
      disconnect() {}
    };

    document.head.innerHTML = '<meta name="csrf-token" content="test-token">';
    document.body.innerHTML = '';
    window.localStorage.clear();
  });

  afterEach(() => {
    cleanupAllBillboardSandboxes();
    global.fetch = originalFetch;
    global.IntersectionObserver = originalIntersectionObserver;
  });

  it('records billboard clicks when an anchor inside an open ShadowRoot is clicked', () => {
    document.body.innerHTML = `
      <div class="crayons-bb--plain"
           data-display-unit
           data-id="55"
           data-category-click="click"
           data-category-impression="impression"
           data-context-type="article"
           data-article-id="12">
        <div class="billboard-shadow-host"
             data-billboard-shadow-host="true"
             data-billboard-id="55"
             data-billboard-template="plain">
          <template shadowrootmode="open">
            <div class="billboard-shadow-body">
              <p id="plain-text">Not a link</p>
              <a id="promo-link" href="/events/live?bb=55"><span>Join Now</span></a>
            </div>
          </template>
        </div>
        <script data-billboard-shadow-bootstrap="true">window.__bootstrapShouldBeSkipped = true;</script>
      </div>
    `;

    const unit = document.querySelector('[data-display-unit]');
    executeBBScripts(unit);
    observeBillboards();

    // executeBBScripts mounted the shadow host directly and skipped the bootstrap script
    expect(window.__bootstrapShouldBeSkipped).toBeUndefined();
    const host = unit.querySelector('[data-billboard-shadow-host="true"]');
    expect(host.shadowRoot).not.toBeNull();

    // Clicking plain text inside shadow DOM should NOT record a click
    host.shadowRoot
      .getElementById('plain-text')
      .dispatchEvent(new MouseEvent('click', { bubbles: true, composed: true }));
    expect(global.fetch).not.toHaveBeenCalled();

    // Clicking inside an <a> in shadow DOM MUST record the billboard click
    host.shadowRoot
      .querySelector('#promo-link span')
      .dispatchEvent(new MouseEvent('click', { bubbles: true, composed: true }));

    expect(global.fetch).toHaveBeenCalledTimes(1);
    expect(global.fetch).toHaveBeenCalledWith(
      '/bb_tabulations',
      expect.objectContaining({
        method: 'POST',
        body: expect.stringContaining('"billboard_id":"55"'),
      }),
    );
    expect(JSON.parse(global.fetch.mock.calls[0][1].body).billboard_event.category).toBe('click');
  });

  it('detects event signup buttons placed inside a raw billboard ShadowRoot', () => {
    document.body.innerHTML = `
      <div data-display-unit data-id="99">
        <div class="billboard-shadow-host" data-billboard-shadow-host="true" data-billboard-id="99">
          <template shadowrootmode="open">
            <div class="billboard-shadow-body">
              <button data-event-signup-button="true" data-event-name-slug="dev" data-event-variation-slug="live">
                RSVP
              </button>
            </div>
          </template>
        </div>
      </div>
    `;

    expect(shouldLoadEventSignupButtons()).toBe(false);
    executeBBScripts(document.body);
    expect(shouldLoadEventSignupButtons()).toBe(true);
  });
});
