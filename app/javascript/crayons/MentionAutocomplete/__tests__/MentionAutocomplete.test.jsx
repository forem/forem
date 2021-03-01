import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import userEvent from '@testing-library/user-event';
import '@testing-library/jest-dom';
import { axe } from 'jest-axe';
import { MentionAutocomplete } from '@crayons/MentionAutocomplete';

describe('<MentionAutocomplete />', () => {
  it('should have no a11y violations when rendered', async () => {
    const { container } = render(
      <MentionAutocomplete
        startText="ab"
        onSelect={() => {}}
        fetchSuggestions={() => Promise.resolve([])}
      />,
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { container } = render(
      <MentionAutocomplete
        startText="ab"
        onSelect={() => {}}
        fetchSuggestions={() => Promise.resolve([])}
      />,
    );

    expect(container.innerHTML).toMatchSnapshot();
  });

  it('should fetch suggestions when search text changes', async () => {
    const mockFetchSuggestions = jest.fn(() => Promise.resolve([]));

    const { getByLabelText } = render(
      <MentionAutocomplete
        startText="us"
        onSelect={() => {}}
        fetchSuggestions={mockFetchSuggestions}
      />,
    );

    expect(mockFetchSuggestions.mock.calls.length).toBe(1);

    const input = getByLabelText('mention user');
    userEvent.type(input, 'e');
    expect(mockFetchSuggestions.mock.calls.length).toBe(2);
  });

  it('should display fetched results', async () => {
    const mockMatchingUser = {
      username: 'user_1',
      name: 'User One',
      profile_image_90: 'example.png',
    };

    const { getByText } = render(
      <MentionAutocomplete
        startText="us"
        onSelect={() => {}}
        fetchSuggestions={() => Promise.resolve([mockMatchingUser])}
      />,
    );

    await waitFor(() => expect(getByText('User One')).toBeInTheDocument());
    expect(getByText('@user_1')).toBeInTheDocument();
  });

  it('should display empty matches state', async () => {
    const { getByText } = render(
      <MentionAutocomplete
        startText="us"
        onSelect={() => {}}
        fetchSuggestions={() => Promise.resolve([])}
      />,
    );

    await waitFor(() =>
      expect(getByText('No results found')).toBeInTheDocument(),
    );
  });
});
