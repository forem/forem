import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { RequestedMembershipSection } from '../ChatChannelSettings/RequestedMembershipSection';

function getEmptyMembershipRequestsData() {
  return {
    requestedMemberships: [],
    currentMembershipRole: 'mod',
  };
}

function getMembershipData() {
  return {
    requestedMemberships: [
      {
        name: 'test user',
        username: 'testusername',
        user_id: '1',
        membership_id: '2',
        role: 'member',
        status: 'requested',
        image: '',
      },
    ],
    membershipType: 'requested',
    currentMembershipRole: 'mod',
  };
}

describe('<RequestedMembershipSection />', () => {
  it('should have no a11y violations when there are no requested memberships', async () => {
    const {
      requestedMemberships,
      currentMembershipRole,
    } = getEmptyMembershipRequestsData();
    const { container } = render(
      <RequestedMembershipSection
        requestedMemberships={requestedMemberships}
        currentMembershipRole={currentMembershipRole}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations when there are requested memberships', async () => {
    const { requestedMemberships, currentMembershipRole } = getMembershipData();
    const { container } = render(
      <RequestedMembershipSection
        requestedMemberships={requestedMemberships}
        currentMembershipRole={currentMembershipRole}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should not render the membership list', () => {
    const {
      requestedMemberships,
      currentMembershipRole,
    } = getEmptyMembershipRequestsData();
    const { getByText, queryByText } = render(
      <RequestedMembershipSection
        requestedMemberships={requestedMemberships}
        currentMembershipRole={currentMembershipRole}
      />,
    );

    getByText('Joining Request');

    expect(
      queryByText('+', { selector: 'button[data-membership-id]' }),
    ).toBeNull();
  });

  it('should render the membership list', () => {
    const { requestedMemberships, currentMembershipRole } = getMembershipData();
    const { queryByText } = render(
      <RequestedMembershipSection
        requestedMemberships={requestedMemberships}
        currentMembershipRole={currentMembershipRole}
      />,
    );

    expect(queryByText('Joining Request')).toBeDefined();
    expect(
      queryByText('+', { selector: 'button[data-membership-id]' }),
    ).toBeDefined();
  });
});
