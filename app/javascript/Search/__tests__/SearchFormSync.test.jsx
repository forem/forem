import { h } from 'preact';
import { fireEvent, render } from '@testing-library/preact';
import { SearchFormSync } from '../SearchFormSync';

// a11y tests are not required for this component as it's job is to provide data to other components.
// There is nothing UI related about this component.
describe('<SearchFormSync />', () => {
  beforeEach(() => {
    global.filterXSS = (text) => text;
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
    document.body.innerHTML +=
      '<div id="mobile-search-container"><form></form></div>';

    fireEvent(
      window,
      new CustomEvent('syncSearchForms', {
        detail: { querystring: `?q=${searchTerm}` },
      }),
    );

    const [desktopSearch, mobileSearch] = await findAllByLabelText('search');

    expect(desktopSearch.value).toEqual(searchTerm);
    expect(mobileSearch.value).toEqual(searchTerm);
  });

  it('should synchronize search forms with empty text if no search term is provided.', async () => {
    // simulates a search result returned which contains the server side rendered search form for mobile only.
    document.body.innerHTML +=
      '<div id="mobile-search-container"><form></form></div>';

    const { findAllByLabelText } = render(<SearchFormSync />);
    fireEvent(
      window,
      new CustomEvent('syncSearchForms', {
        detail: { querystring: '?q=' },
      }),
    );

    const [desktopSearch, mobileSearch] = await findAllByLabelText('search');
    expect(desktopSearch.value).toEqual('');
    expect(mobileSearch.value).toEqual('');
  });
});
