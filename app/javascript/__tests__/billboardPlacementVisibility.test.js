import {
  observeBillboards,
  revealBillboardPlacement,
} from '../packs/billboardAfterRenderActions';

// Drives the real impression code path (IntersectionObserver -> trackAdImpression)
// for billboards whose placement area is configured as "hidden by default".
describe('billboard placement visibility', () => {
  let originalFetch;
  let observers;

  const billboardMarkup = ({ id, placementArea, hidden = true }) => `
    <div data-display-unit data-id="${id}"
      data-placement-area="${placementArea}"
      ${hidden ? 'data-placement-hidden="true"' : ''}
      data-context-type="article" data-category-impression="impression"></div>
  `;

  const renderPage = (content) => {
    document.body.innerHTML = `<div id="page-content">${content}</div>`;
  };

  const billboard = (id) => document.querySelector(`[data-id="${id}"]`);

  // Reports the billboard as on screen to every observer watching it.
  const scrollIntoView = (element) => {
    observers
      .filter(({ targets }) => targets.includes(element))
      .forEach(({ callback }) =>
        callback([
          { isIntersecting: true, intersectionRatio: 1, target: element },
        ]),
      );
    jest.advanceTimersByTime(200); // trackAdImpression fires on a 200ms timer
  };

  const impressionPostsFor = (id) =>
    global.fetch.mock.calls.filter(
      ([url, options]) =>
        url === '/bb_tabulations' &&
        JSON.parse(options.body).billboard_event.billboard_id === id,
    );

  beforeEach(() => {
    jest.useFakeTimers();
    observers = [];
    originalFetch = global.fetch;
    global.fetch = jest.fn(() => Promise.resolve({}));
    global.IntersectionObserver = class {
      constructor(callback) {
        this.callback = callback;
        this.targets = [];
        observers.push(this);
      }
      observe(target) {
        this.targets.push(target);
      }
      unobserve() {}
      disconnect() {}
    };
  });

  afterEach(() => {
    global.fetch = originalFetch;
    jest.useRealTimers();
  });

  it('records no impression for a hidden billboard', () => {
    renderPage(billboardMarkup({ id: '1', placementArea: 'post_sidebar' }));

    observeBillboards();
    scrollIntoView(billboard('1'));

    expect(impressionPostsFor('1')).toHaveLength(0);
    expect(billboard('1').dataset.impressionRecorded).toBeUndefined();
  });

  it('still records impressions for billboards in placements that are not hidden', () => {
    renderPage(
      billboardMarkup({
        id: '1',
        placementArea: 'post_sidebar',
        hidden: false,
      }),
    );

    observeBillboards();
    scrollIntoView(billboard('1'));

    expect(impressionPostsFor('1')).toHaveLength(1);
  });

  it('records exactly one impression once a hidden billboard is revealed and seen', () => {
    renderPage(billboardMarkup({ id: '1', placementArea: 'post_sidebar' }));
    observeBillboards();
    scrollIntoView(billboard('1'));
    expect(impressionPostsFor('1')).toHaveLength(0);

    revealBillboardPlacement('post_sidebar');

    expect(billboard('1').dataset.placementHidden).toBe('false');
    scrollIntoView(billboard('1'));
    expect(impressionPostsFor('1')).toHaveLength(1);
  });

  it('observes revealed billboards afresh so one already on screen counts without scrolling', () => {
    renderPage(billboardMarkup({ id: '1', placementArea: 'post_sidebar' }));
    observeBillboards();
    const observerCountBeforeReveal = observers.length;

    revealBillboardPlacement('post_sidebar');

    const revealObserver = observers[observerCountBeforeReveal];
    expect(revealObserver.targets).toEqual([billboard('1')]);
  });

  it('only reveals billboards in the requested placement area', () => {
    renderPage(
      billboardMarkup({ id: '1', placementArea: 'post_sidebar' }) +
        billboardMarkup({ id: '2', placementArea: 'post_comments' }),
    );
    observeBillboards();

    revealBillboardPlacement('post_sidebar');
    scrollIntoView(billboard('1'));
    scrollIntoView(billboard('2'));

    expect(billboard('2').dataset.placementHidden).toBe('true');
    expect(impressionPostsFor('1')).toHaveLength(1);
    expect(impressionPostsFor('2')).toHaveLength(0);
  });

  it('reveals a billboard that finishes loading after its placement was revealed', () => {
    renderPage('<div class="sidebar-bb"></div>');
    revealBillboardPlacement('post_sidebar');

    document.querySelector('.sidebar-bb').innerHTML = billboardMarkup({
      id: '1',
      placementArea: 'post_sidebar',
    });
    observeBillboards();
    scrollIntoView(billboard('1'));

    expect(billboard('1').dataset.placementHidden).toBe('false');
    expect(impressionPostsFor('1')).toHaveLength(1);
  });

  it('forgets revealed placements when InstantClick swaps in the next page', () => {
    renderPage('');
    revealBillboardPlacement('post_sidebar');

    renderPage(billboardMarkup({ id: '1', placementArea: 'post_sidebar' }));
    observeBillboards();
    scrollIntoView(billboard('1'));

    expect(billboard('1').dataset.placementHidden).toBe('true');
    expect(impressionPostsFor('1')).toHaveLength(0);
  });

  it('ignores a reveal without a placement area', () => {
    renderPage(billboardMarkup({ id: '1', placementArea: 'post_sidebar' }));

    revealBillboardPlacement(undefined);

    expect(billboard('1').dataset.placementHidden).toBe('true');
  });
});
