import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { LeaveMembershipSection } from '../ChatChannelSettings/LeaveMembershipSection';

describe('<LeaveMembershipSection />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<LeaveMembershipSection />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { queryByText } = render(<LeaveMembershipSection />);

    expect(queryByText('Danger Zone')).toBeDefined();
    expect(queryByText('Leave Channel')).toBeDefined();
  });

  it('should have user leave channel when leave button is clicked', () => {
    const leaveHandler = jest.fn();
    const { getByText } = render(
      <LeaveMembershipSection handleleaveChannelMembership={leaveHandler} />,
    );
    const leaveButton = getByText('Leave Channel');

    leaveButton.click();

    expect(leaveHandler).toHaveBeenCalledTimes(1);
  });
});
