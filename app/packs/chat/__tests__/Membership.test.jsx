import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Membership } from '../ChatChannelSettings/MembershipManager/Membership';

const membershipData = {
  name: 'dummy Name',
  user_id: 1,
  chat_channel_id: 2,
  membership_id: 1,
  username: 'dummyuser',
};

const currentModMembership = {
  name: 'dummy user',
  username: 'dummyuser',
  user_id: 1,
  chat_channel_id: 2,
  status: 'active',
  role: 'mod',
};

describe('<Membership />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <Membership
        currentMembership={currentModMembership}
        membership={membershipData}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { queryByText } = render(
      <Membership
        currentMembership={currentModMembership}
        membership={membershipData}
      />,
    );

    expect(queryByText('dummy user')).toBeDefined();
  });
});
