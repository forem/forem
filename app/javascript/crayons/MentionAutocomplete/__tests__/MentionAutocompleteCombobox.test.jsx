import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import userEvent from '@testing-library/user-event';
import '@testing-library/jest-dom';
import { axe } from 'jest-axe';
import { MentionAutocompleteCombobox } from '../MentionAutocompleteCombobox';

describe('<MentionAutocomplete />', () => {
  const mockCoords = {
    x: 0,
    y: 0,
  };

  const mockOnSelect = jest.fn();
  const mockOnSearchtermChange = jest.fn();

  it('should have no a11y violations when rendered', async () => {
    const { container } = render(
      <MentionAutocompleteCombobox
        onSelect={mockOnSelect}
        onSearchTermChange={mockOnSearchtermChange}
        fetchSuggestions={() => Promise.resolve([])}
        placementCoords={mockCoords}
      />,
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { container } = render(
      <MentionAutocompleteCombobox
        onSelect={mockOnSelect}
        onSearchTermChange={mockOnSearchtermChange}
        fetchSuggestions={() => Promise.resolve([])}
        placementCoords={mockCoords}
      />,
    );

    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should not fetch suggestions with less than three characters', async () => {
    const mockFetchSuggestions = jest.fn();

    const { getByLabelText } = render(
      <MentionAutocompleteCombobox
        startText="us"
        onSelect={mockOnSelect}
        onSearchTermChange={mockOnSearchtermChange}
        fetchSuggestions={mockFetchSuggestions}
        placementCoords={mockCoords}
      />,
    );

    expect(mockFetchSuggestions.mock.calls.length).toBe(0);
    const input = getByLabelText('mention user');
    userEvent.type(input, 'us');
    expect(mockFetchSuggestions.mock.calls.length).toBe(0);
  });

  it('should fetch and display suggestions when search text changes to more than 3 characters', async () => {
    const mockMatchingUser = {
      username: 'user_1',
      name: 'User One',
      profile_image_90: 'example.png',
    };
    const mockFetchSuggestions = jest.fn(() =>
      Promise.resolve([mockMatchingUser]),
    );

    const { getByLabelText, getByText } = render(
      <MentionAutocompleteCombobox
        onSelect={mockOnSelect}
        onSearchTermChange={mockOnSearchtermChange}
        fetchSuggestions={mockFetchSuggestions}
        placementCoords={mockCoords}
      />,
    );

    expect(mockFetchSuggestions.mock.calls.length).toBe(0);

    const input = getByLabelText('mention user');
    userEvent.type(input, 'use');
    expect(mockFetchSuggestions.mock.calls.length).toBe(1);

    await waitFor(() => expect(getByText('User One')).toBeInTheDocument());
    expect(getByText('@user_1')).toBeInTheDocument();
  });

  it('should display empty matches state', async () => {
    const { getByText, getByLabelText } = render(
      <MentionAutocompleteCombobox
        fetchSuggestions={() => Promise.resolve([])}
        onSelect={mockOnSelect}
        onSearchTermChange={mockOnSearchtermChange}
        placementCoords={mockCoords}
      />,
    );

    const input = getByLabelText('mention user');
    userEvent.type(input, 'us');

    await waitFor(() =>
      expect(getByText('No results found')).toBeInTheDocument(),
    );
  });
});
