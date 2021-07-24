import { h } from 'preact';
import { render, fireEvent, waitFor } from '@testing-library/preact';
import userEvent from '@testing-library/user-event';

import { axe } from 'jest-axe';
import { Search } from '../Search';

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
    };
    const { container } = render(<Search {...props} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have a search textbox', () => {
    const props = {
      searchTerm: 'fish',
      setSearchTerm: jest.fn(),
    };

    const { getByRole } = render(<Search {...props} />);

    const searchInput = getByRole('textbox', { name: /search/i });

    expect(searchInput.value).toEqual('fish');
    expect(searchInput.getAttribute('placeholder')).toEqual('Search...');
    expect(searchInput.getAttribute('autocomplete')).toEqual('off');
  });

  it('should contain text the user entered in the search textbox', async () => {
    const props = {
      searchTerm: 'fish',
      setSearchTerm: jest.fn(),
    };
    const { getByRole, findByRole } = render(<Search {...props} />);

    let searchInput = getByRole('textbox', { name: /search/i });

    expect(searchInput.value).toEqual('fish');

    fireEvent.change(searchInput, { target: { value: 'hello' } });

    searchInput = await findByRole('textbox', { name: /search/i });

    expect(searchInput.value).toEqual('hello');
  });

  it('should set the search term', async () => {
    const props = {
      searchTerm: '',
      setSearchTerm: jest.fn(),
    };
    const { getByRole } = render(<Search {...props} />);

    const searchInput = getByRole('textbox', { name: /search/i });

    expect(searchInput.value).toEqual('');

    userEvent.type(searchInput, 'hello');

    waitFor(() => {
      expect(searchInput.value).toEqual('hello');
      expect(props.setSearchTerm).toHaveBeenCalledWith('hello');
    });
  });

  it('should submit the search form', async () => {
    const props = {
      searchTerm: '',
      setSearchTerm: jest.fn(),
      onSubmitSearch: jest.fn(),
    };
    const { getByRole, findByRole } = render(<Search {...props} />);

    let searchInput = getByRole('textbox', { name: /search/i });

    expect(searchInput.value).toEqual('');

    userEvent.type(searchInput, 'hello');

    fireEvent.submit(getByRole('search'));

    searchInput = await findByRole('textbox', { name: /search/i });

    waitFor(() => {
      expect(searchInput.value).toEqual('hello');
      expect(props.onSubmitSearch).toHaveBeenCalledWith('hello');
    });
  });

  it('should be listening for history state changes', async () => {
    // This is an implementation detail, but I want to make sure that this
    // listener is registered as it affects the UI.
    jest.spyOn(window, 'addEventListener');

    const props = {
      searchTerm: '',
      setSearchTerm: jest.fn(),
    };
    render(<Search {...props} />);

    expect(window.addEventListener).toHaveBeenNthCalledWith(
      1,
      'popstate',
      expect.any(Function),
    );
  });

  it('should stop listening for history state changes when the component is destroyed', async () => {
    // This is an implementation detail, but I want to make sure that this
    // listener is unregistered as it affects the UI.
    jest.spyOn(window, 'removeEventListener');

    const props = {
      searchTerm: '',
      setSearchTerm: jest.fn(),
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
