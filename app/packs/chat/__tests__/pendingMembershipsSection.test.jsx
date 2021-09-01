import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { PendingMembershipSection } from '../ChatChannelSettings/PendingMembershipSection';

function getEmptyMembershipData() {
  return {
    activeMemberships: [],
    currentMembershipRole: 'mod',
  };
}

function getMembershipData() {
  return {
    pendingMemberships: [
      {
        name: 'test user',
        username: 'testusername',
        user_id: '1',
        membership_id: '2',
        role: 'mod',
        status: 'active',
        image: '',
      },
    ],
    membershipType: 'active',
    currentMembershipRole: 'mod',
  };
}

describe('<PendingMembershipSection />', () => {
  it('should have no a11y violations when there are no members', async () => {
    const {
      pendingMemberships,
      currentMembershipRole,
    } = getEmptyMembershipData();
    const { container } = render(
      <PendingMembershipSection
        pendingMemberships={pendingMemberships}
        currentMembershipRole={currentMembershipRole}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations when there are members', async () => {
    const { pendingMemberships, currentMembershipRole } = getMembershipData();
    const { container } = render(
      <PendingMembershipSection
        pendingMemberships={pendingMemberships}
        currentMembershipRole={currentMembershipRole}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should not render the membership list', () => {
    const {
      pendingMemberships,
      currentMembershipRole,
    } = getEmptyMembershipData();
    const { getByTestId } = render(
      <PendingMembershipSection
        pendingMemberships={pendingMemberships}
        currentMembershipRole={currentMembershipRole}
      />,
    );

    // no users to be found
    const pendingMembershipsWrapper = getByTestId('pending-memberships');

    expect(Number(pendingMembershipsWrapper.dataset.pendingCount)).toEqual(0);
  });

  it('should render the membership list', () => {
    const { pendingMemberships, currentMembershipRole } = getMembershipData();
    const { getByTestId } = render(
      <PendingMembershipSection
        pendingMemberships={pendingMemberships}
        currentMembershipRole={currentMembershipRole}
      />,
    );

    // no users to be found
    const pendingMembershipsWrapper = getByTestId('pending-memberships');

    expect(
      Number(pendingMembershipsWrapper.dataset.pendingCount),
    ).toBeGreaterThanOrEqual(1);
  });
});
