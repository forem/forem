import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ManageActiveMembership } from '../ChatChannelSettings/MembershipManager/ManageActiveMembership';

const currentModMembership = {
  name: 'dummy user',
  username: 'dummyuser',
  user_id: 1,
  chat_channel_id: 2,
  status: 'active',
  role: 'mod',
};

describe('<ManageActiveMembership />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <ManageActiveMembership
        invitationLink={'https://dummy-invitation.link'}
        currentMembership={currentModMembership}
        activeMemberships={[]}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { queryByText, queryByPlaceholderText } = render(
      <ManageActiveMembership
        invitationLink={'https://dummy-invitation.link'}
        currentMembership={currentModMembership}
        activeMemberships={[]}
      />,
    );

    expect(queryByText('Chat Channel Membership manager')).toBeDefined();
    expect(queryByPlaceholderText('Search Member...')).toBeDefined();
  });
});
