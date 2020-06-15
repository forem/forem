import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import Membership from '../ChatChannelSettings/Membership';

function getModUser() {
  return {
    membership: {
      name: 'test user',
      username: 'testusername',
      user_id: '1',
      membership_id: '2',
      role: 'mod',
      status: 'active',
      image: '',
    },
    membershipType: 'active',
    currentMembershipRole: 'mod',
  };
}

function getMemberUser() {
  return {
    membership: {
      name: 'test user',
      username: 'testusername',
      user_id: '1',
      membership_id: '2',
      role: 'member',
      status: 'active',
      image: '',
    },
    membershipType: 'requested',
    currentMembershipRole: 'mod',
  };
}

describe('<Membership />', () => {
  it('should have no a11y violations for a moderator user', async () => {
    const { membership, membershipType, currentMembershipRole } = getModUser();
    const { container } = render(
      <Membership
        membership={membership}
        membershipType={membershipType}
        currentMembershipRole={currentMembershipRole}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations for a member user', async () => {
    const {
      membership,
      membershipType,
      currentMembershipRole,
    } = getMemberUser();
    const { container } = render(
      <Membership
        membership={membership}
        membershipType={membershipType}
        currentMembershipRole={currentMembershipRole}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render a moderator user', () => {
    const { membership, membershipType, currentMembershipRole } = getModUser();
    const { getByAltText, getByTitle } = render(
      <Membership
        membership={membership}
        membershipType={membershipType}
        currentMembershipRole={currentMembershipRole}
      />,
    );
    const userProfileLink = getByTitle('test user profile');

    expect(userProfileLink.getAttribute('href')).toEqual('/testusername');

    getByAltText('test user profile');
  });

  it('should render a member user', () => {
    const {
      membership,
      membershipType,
      currentMembershipRole,
    } = getMemberUser();
    const { getByAltText, getByTitle, getByText } = render(
      <Membership
        membership={membership}
        membershipType={membershipType}
        currentMembershipRole={currentMembershipRole}
      />,
    );

    // users requesting to join channel
    const userProfileLink = getByTitle('test user profile');

    expect(userProfileLink.getAttribute('href')).toEqual('/testusername');

    getByAltText('test user profile');

    const addButton = getByText('+', {
      selector: 'button',
    });

    expect(addButton.dataset.membershipId).toEqual('2');

    const deleteButton = getByText('x', { selector: 'button' });

    expect(deleteButton.dataset.membershipId).toEqual('2');
    expect(deleteButton.dataset.membershipStatus).toEqual('active');
  });

  it('should not show add/remove buttons for a moderator', () => {
    const { membership, membershipType, currentMembershipRole } = getModUser();
    const { queryByText } = render(
      <Membership
        membership={membership}
        membershipType={membershipType}
        currentMembershipRole={currentMembershipRole}
      />,
    );

    // a moderator should not have add or remove buttons
    expect(
      queryByText('+', {
        selector: 'button',
      }),
    ).toBeNull();
    expect(
      queryByText('x', {
        selector: 'button',
      }),
    ).toBeNull();
  });

  it('should show add/remove buttons for a member', () => {
    const {
      membership,
      membershipType,
      currentMembershipRole,
    } = getMemberUser();
    const { getByText } = render(
      <Membership
        membership={membership}
        membershipType={membershipType}
        currentMembershipRole={currentMembershipRole}
      />,
    );
    getByText('+', {
      selector: 'button',
    });
    getByText('x', {
      selector: 'button',
    });
  });
});
