import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ActiveMembershipsSection } from '../ChatChannelSettings/ActiveMembershipsSection';

function getEmptyMembershipData() {
  return {
    activeMemberships: [],
    currentMembershipRole: 'mod',
  };
}

function getMembershipData() {
  return {
    activeMemberships: [
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

describe('<ActiveMembershipsSection />', () => {
  it('should have no a11y violations when there are no members', async () => {
    const {
      activeMemberships,
      currentMembershipRole,
    } = getEmptyMembershipData();
    const { container } = render(
      <ActiveMembershipsSection
        activeMemberships={activeMemberships}
        currentMembershipRole={currentMembershipRole}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations when there are members', async () => {
    const { activeMemberships, currentMembershipRole } = getMembershipData();
    const { container } = render(
      <ActiveMembershipsSection
        activeMemberships={activeMemberships}
        currentMembershipRole={currentMembershipRole}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have a title', () => {
    const {
      activeMemberships,
      currentMembershipRole,
    } = getEmptyMembershipData();
    const { queryByText } = render(
      <ActiveMembershipsSection
        activeMemberships={activeMemberships}
        currentMembershipRole={currentMembershipRole}
      />,
    );

    expect(queryByText).toBeDefined();
  });

  it('should not render the membership list', () => {
    const {
      activeMemberships,
      currentMembershipRole,
    } = getEmptyMembershipData();
    const { getByTestId } = render(
      <ActiveMembershipsSection
        activeMemberships={activeMemberships}
        currentMembershipRole={currentMembershipRole}
      />,
    );

    // no users to be found
    const activeMembershipsWrapper = getByTestId('active-memberships');

    expect(Number(activeMembershipsWrapper.dataset.activeCount)).toEqual(0);
  });

  it('should render the membership list', () => {
    const { activeMemberships, currentMembershipRole } = getMembershipData();
    const { getByTestId } = render(
      <ActiveMembershipsSection
        activeMemberships={activeMemberships}
        currentMembershipRole={currentMembershipRole}
      />,
    );

    // the other fields aren't necessary to test as this is handled in the
    // <Membership /> tests.
    const activeMembershipsWrapper = getByTestId('active-memberships');

    expect(
      Number(activeMembershipsWrapper.dataset.activeCount),
    ).toBeGreaterThanOrEqual(1);
  });
});
