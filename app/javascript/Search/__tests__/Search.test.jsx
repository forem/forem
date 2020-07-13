import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';

import { axe } from 'jest-axe';
import { Search } from '../Search';

describe('<Search />', () => {
  beforeEach(() => {
    global.filterXSS = jest.fn();
    global.InstantClick = jest.fn(() => ({
      on: jest.fn(),
      preload: jest.fn(),
      display: jest.fn(),
    }))();
    global.instantClick = jest.fn(() => ({}))();
  });

  it('should have no a11y violations', async () => {
    const { container } = render(<Search />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have a search textbox', () => {
    const { getByLabelText } = render(<Search />);

    const searchInput = getByLabelText(/search/i);

    expect(searchInput.getAttribute('placeholder')).toEqual('Search...');
    expect(searchInput.getAttribute('autocomplete')).toEqual('off');
  });

  it('should contain text the user entered in the search textbox', async () => {
    const { getByLabelText, findByLabelText } = render(<Search />);

    let searchInput = getByLabelText(/search/i);

    expect(searchInput.value).toEqual('');

    // user.type doesn't work in the case of
    // search as the current implementation is relying on keydown
    // events
    fireEvent.keyDown(searchInput, {
      key: 'Enter',
      keyCode: 13,
      which: 13,
      target: { value: 'hello' },
    });

    searchInput = await findByLabelText(/search/i);

    expect(searchInput.value).toEqual('hello');
  });

  it('should submit the search form', async () => {
    jest.spyOn(Search.prototype, 'search');

    const { getByLabelText, findByLabelText } = render(<Search />);

    let searchInput = getByLabelText(/search/i);

    expect(searchInput.value).toEqual('');

    // user.type doesn't work in the case of
    // search as the current implementation is relying on keydown
    // events
    fireEvent.keyDown(searchInput, {
      key: 'Enter',
      keyCode: 13,
      which: 13,
      target: { value: 'hello' },
    });

    searchInput = await findByLabelText(/search/i);

    expect(searchInput.value).toEqual('hello');
    expect(Search.prototype.search).toHaveBeenCalledWith('Enter', 'hello');
  });
});
