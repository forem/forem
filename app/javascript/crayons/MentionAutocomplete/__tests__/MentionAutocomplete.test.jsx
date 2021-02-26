import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { MentionAutocomplete } from '@crayons';

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
});
