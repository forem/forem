import { h } from 'preact';
import { fireEvent, render } from '@testing-library/preact';
import { SearchFormSync } from '../SearchFormSync';

function setWindowLocation(url = '') {
  delete window.location; // Inspired from https://www.benmvp.com/blog/mocking-window-location-methods-jest-jsdom/
  window.location = new URL(url);
}

// a11y tests are not required for this component as it's job is to provide data to other components.
// There is nothing UI related about this component.
describe('<SearchFormSync />', () => {
  // For some reason when document.body is used for renders, we need to clear out the rendered markup in it.
  // My guess is that Preact testing library handles this internally when using the default container to render in.

  beforeEach(() => {
    setWindowLocation(`https://locahost:3000/`);

    // The body is being cleared out because we are using it as the root element for the tests.
    // Typically using the document.body as the root for rendering of components in tests is not necessary,
    // but in the case of this component, it renders a portal, and this seemed to be the only way to get these
    // tests to render portals.
    document.body.innerHTML = '';

    global.InstantClick = jest.fn(() => ({
      on: jest.fn(),
      off: jest.fn(),
      preload: jest.fn(),
      display: jest.fn(),
    }))();
  });

  it('should synchronize search forms', async () => {
    const { findByLabelText, findAllByLabelText } = render(<SearchFormSync />, {
      container: document.body,
    });

    // Only one input is rendered at this point because the synchSearchForms custom event is what
    // tells us that there is a new search form to sync with the existing one.
    const searchInput = await findByLabelText('search');

    // Because window.location has no search term in it's URL
    expect(searchInput.value).toEqual('');

    // https://www.theatlantic.com/technology/archive/2012/09/here-it-is-the-best-word-ever/262348/
    const searchTerm = 'diphthong';

    // simulates a search result returned which contains the server side rendered search form for mobile only.
    setWindowLocation(`https://locahost:3000/search?q=${searchTerm}`);

    // This part of the DOM would be rendered in the search results from the server side.
    // See search.html.erb.
    document.body.innerHTML =
      '<div id="mobile-search-container"><form></form></div>';

    fireEvent(
      window,
      new CustomEvent('syncSearchForms', {
        detail: { querystring: window.location.search },
      }),
    );

    const [desktopSearch, mobileSearch] = await findAllByLabelText('search');

    expect(desktopSearch.value).toEqual(searchTerm);
    expect(mobileSearch.value).toEqual(searchTerm);
  });

  it('should synchronize search forms on a subsequent search', async () => {
    const { findByLabelText, findAllByLabelText } = render(<SearchFormSync />, {
      container: document.body,
    });

    // Only one input is rendered at this point because the synchSearchForms custom event is what
    // tells us that there is a new search form to sync with the existing one.
    const searchInput = await findByLabelText('search');

    // Because window.location has no search term in it's URL
    expect(searchInput.value).toEqual('');

    // https://www.theatlantic.com/technology/archive/2012/09/here-it-is-the-best-word-ever/262348/
    const searchTerm = 'diphthong';

    // simulates a search result returned which contains the server side rendered search form for mobile only.
    setWindowLocation(`https://locahost:3000/search?q=${searchTerm}`);

    // This part of the DOM would be rendered in the search results from the server side.
    // See search.html.erb.
    document.body.innerHTML =
      '<div id="mobile-search-container"><form></form></div>';

    fireEvent(
      window,
      new CustomEvent('syncSearchForms', {
        detail: { querystring: window.location.search },
      }),
    );

    let [desktopSearch, mobileSearch] = await findAllByLabelText('search');

    expect(desktopSearch.value).toEqual(searchTerm);
    expect(mobileSearch.value).toEqual(searchTerm);

    const searchTerm2 = 'diphthong2';

    // simulates a search result returned which contains the server side rendered search form for mobile only.
    setWindowLocation(`https://locahost:3000/search?q=${searchTerm2}`);

    // This part of the DOM would be rendered in the search results from the server side.
    // See search.html.erb.
    document.body.innerHTML =
      '<div id="mobile-search-container"><form></form></div>';

    fireEvent(
      window,
      new CustomEvent('syncSearchForms', {
        detail: { querystring: window.location.search },
      }),
    );

    [desktopSearch, mobileSearch] = await findAllByLabelText('search');

    expect(desktopSearch.value).toEqual(searchTerm2);
    expect(mobileSearch.value).toEqual(searchTerm2);
  });
});
