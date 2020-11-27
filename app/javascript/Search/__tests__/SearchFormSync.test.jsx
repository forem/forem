import { h } from 'preact';
import { fireEvent, render } from '@testing-library/preact';
import { SearchFormSync } from '../SearchFormSync';

// a11y tests are not required for this component as it's job is to provide data to other components.
// There is nothing UI related about this component.
describe('<SearchFormSync />', () => {
  beforeEach(() => {
    delete window.location;
    window.location = new URL(`https://locahost:3000/`);
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
    delete window.location;
    window.location = new URL(`https://locahost:3000/search?q=${searchTerm}`);

    // This part of the DOM would be rendered in the search results from the server side.
    // See search.html.erb.
    // I'm not sure why, but with a portal being created in the code, it seems at least in the test
    // scenario, the body needs to be reset.
    document.body.innerHTML =
      '<div id="mobile-search-container"><form></form></div>';

    fireEvent(
      window,
      new CustomEvent('syncSearchForms', {
        detail: { querystring: window.location.search },
      }),
    );

    // TODO: Near future during work for #10424. I can't figure out why yet, but only in the test scenario does it generate
    // an extra form. It's appears to be remnants of the previous render. Need to investigate.
    // This is why the first item in the array of elements is skipped.
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
    delete window.location;
    window.location = new URL(`https://locahost:3000/search?q=${searchTerm}`);

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

    // TODO: Near future during work for #10424. I can't figure out why yet, but only in the test scenario does it generate
    // an extra form. It's appears to be remnants of the previous render. Need to investigate.
    // This is why the first item in the array of elements is skipped.
    let [desktopSearch, mobileSearch] = await findAllByLabelText('search');

    expect(desktopSearch.value).toEqual(searchTerm);
    expect(mobileSearch.value).toEqual(searchTerm);

    const searchTerm2 = 'diphthong2';

    // simulates a search result returned which contains the server side rendered search form for mobile only.
    delete window.location;
    window.location = new URL(`https://locahost:3000/search?q=${searchTerm2}`);

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
