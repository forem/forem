import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ModFaqSection } from '../ChatChannelSettings/ModFaqSection';

describe('<ChannelDescriptionSection />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<ModFaqSection />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { queryByText } = render(<ModFaqSection />);

    expect(
      queryByText(/^Questions about Connect Channel moderation\? Contact/),
    ).toBeDefined();
  });
});
