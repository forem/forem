import { h } from 'preact';
import { fireEvent, render } from '@testing-library/preact';
import { SearchFormSync } from '../SearchFormSync';

// a11y tests are not required for this component as it's job is to provide data to other components.
// There is nothing UI related about this component.
describe('<SearchFormSync />', () => {
  beforeEach(() => {
    global.filterXSS = (x) => x;
    global.InstantClick = jest.fn(() => ({
      on: jest.fn(),
      off: jest.fn(),
      preload: jest.fn(),
      display: jest.fn(),
    }))();
    global.instantClick = jest.fn(() => ({}))();
  });

  it('should synchronize search forms', async () => {
    // The portal root is to simulate the mobile search form which is part of the
    // search results page that gets refreshed on every search.
    const portalRoot = document.createElement('div');
    portalRoot.setAttribute('id', 'mobile-search-container');
    document.body.appendChild(portalRoot);

    const { findAllByLabelText } = render(<SearchFormSync />, {
      container: document.body,
    });

    // https://www.theatlantic.com/technology/archive/2012/09/here-it-is-the-best-word-ever/262348/
    const searchTerm = 'diphthong';

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
    // The portal root is to simulate the mobile search form which is part of the
    // search results page that gets refreshed on every search.
    const portalRoot = document.createElement('div');
    portalRoot.setAttribute('id', 'mobile-search-container');
    document.body.appendChild(portalRoot);

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
