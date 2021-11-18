import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { InviationLinkManager } from '../ChatChannelSettings/MembershipManager/InvitationLinkManager';

const currentModMembership = {
  name: 'dummy user',
  username: 'dummyuser',
  user_id: 1,
  chat_channel_id: 2,
  status: 'active',
  role: 'mod',
};

const currentMemberMembership = {
  name: 'dummy member',
  username: 'dummymember',
  user_id: 1,
  chat_channel_id: 2,
  status: 'active',
  role: 'member',
};

const svg = (
  <svg
    width="24"
    height="24"
    viewBox="0 0 24 24"
    className="crayons-icon copy-icon"
    xmlns="http://www.w3.org/2000/svg"
    role="img"
    aria-labelledby="fc5f15add1e114844f5e"
  >
    <title id="fc5f15add1e114844f5e">Copy Invitation Url</title>
    <path d="M7 6V3a1 1 0 011-1h12a1 1 0 011 1v14a1 1 0 01-1 1h-3v3c0 .552-.45 1-1.007 1H4.007A1 1 0 013 21l.003-14c0-.552.45-1 1.007-1H7zm2 0h8v10h2V4H9v2zm-2 5v2h6v-2H7zm0 4v2h6v-2H7z" />
  </svg>
);

describe('<InviationLinkManager />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <InviationLinkManager
        invitationLink="https://dummy-invitation.link"
        currentMembership={currentModMembership}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { queryByText } = render(
      <InviationLinkManager
        invitationLink="https://dummy-invitation.link"
        currentMembership={currentModMembership}
      />,
    );

    expect(queryByText('https://dummy-invitation.link')).toBeDefined();
    expect(queryByText('Invitation Link')).toBeDefined();
  });

  it('should not render', () => {
    const { rerender } = render(
      <InviationLinkManager
        invitationLink="https://dummy-invitation.link"
        currentMembership={currentMemberMembership}
      />,
    );

    expect(rerender()).toEqual(undefined);
  });
});
