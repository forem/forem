import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ChatChannelSettings } from '../ChatChannelSettings/ChatChannelSettings';

// TODO: These tests are imcomplete, but currently
// this is simply a migration to preact-testing-library.
// More tests should be added here.
describe('<ChatChannelSettings />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <ChatChannelSettings activeMembershipId={12} />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render if there are no channels', () => {
    const { container } = render(
      <ChatChannelSettings activeMembershipId={12} />,
    );

    expect(container.firstElementChild).toBeNull();
  });
});
