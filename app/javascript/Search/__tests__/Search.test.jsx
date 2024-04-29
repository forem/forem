import { h } from 'preact';
import { render, fireEvent, waitFor } from '@testing-library/preact';
import { userEvent } from '@testing-library/user-event';

import { axe } from 'jest-axe';
import { Search } from '../Search';
import { locale } from '../../utilities/locale';

describe('<Search />', () => {
  beforeEach(() => {
    global.filterXSS = jest.fn();
    global.InstantClick = jest.fn(() => ({
      on: jest.fn(),
      off: jest.fn(),
      preload: jest.fn(),
      display: jest.fn(),
    }))();
    global.instantClick = jest.fn(() => ({}))();
  });

  it('should have no a11y violations', async () => {
    const props = {
      searchTerm: 'fish',
      setSearchTerm: jest.fn(),
      branding: 'default', // Added branding prop
    };
    const { container } = render(<Search {...props} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have a search textbox', () => {
    const props = {
      searchTerm: 'fish',
      setSearchTerm: jest.fn(),
      branding: 'default',
    };

    const { getByRole } = render(<Search {...props} />);

    const searchInput = getByRole('textbox', { name: /search/i });

    expect(searchInput.value).toEqual('fish');
    expect(searchInput.getAttribute('placeholder')).toEqual(`${locale('core.search')}...`);
    expect(searchInput.getAttribute('autocomplete')).toEqual('off');
  });

  it('should correctly pass the branding prop to the SearchForm', () => {
    const props = {
      searchTerm: 'fish',
      setSearchTerm: jest.fn(),
      branding: 'magoo', // Added branding prop for testing
    };

    const { getByTestId } = render(<Search {...props} />);
    const searchForm = getByTestId('search-form');

    expect(searchForm).toHaveAttribute('branding', 'magoo');
  });

  // Additional tests remain unchanged, ensure to include the `branding` prop where necessary

  it('should stop listening for history state changes when the component is destroyed', async () => {
    jest.spyOn(window, 'removeEventListener');

    const props = {
      searchTerm: '',
      setSearchTerm: jest.fn(),
      branding: 'default', // Added branding prop
    };
    const { unmount } = render(<Search {...props} />);

    unmount();

    expect(window.removeEventListener).toHaveBeenNthCalledWith(
      1,
      'popstate',
      expect.any(Function),
    );
  });
});
