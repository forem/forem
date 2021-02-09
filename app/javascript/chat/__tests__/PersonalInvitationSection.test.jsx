import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { PersonalInvitationSection } from '../RequestManager/PersonalInvitationSection';

const data = {
  userInvitations: [
    {
      name: 'Demo name',
      membership_id: 11,
      user_id: 10,
      role: 'member',
      image: '/image',
      username: 'demousername',
      status: 'joining_request',
      chat_channel_name: 'demo channel',
    },
  ],
  noUserInvitations: [],
};

describe('<PersonalInvitationSection />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <PersonalInvitationSection userInvitations={data.userInvitations} />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render the the component', () => {
    const { getByTestId } = render(
      <PersonalInvitationSection userInvitations={data.userInvitations} />,
    );

    const userInvitationsWrapper = getByTestId('user-invitations');
    expect(
      Number(userInvitationsWrapper.dataset.activeCount),
    ).toBeGreaterThanOrEqual(1);
  });
});
