import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { ChatChannelMembershipSection } from '../ChatChannelSettings/ChatChannelMembershipSection';

describe('<ChatChannelMembershipSection />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <ChatChannelMembershipSection
        pendingMemberships={[]}
        requestedMemberships={[]}
        activeMemberships={[]}
        currentMembershipRole="mod"
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render when no memberships', () => {
    const { getByText, getByTestId } = render(
      <ChatChannelMembershipSection
        pendingMemberships={[]}
        requestedMemberships={[]}
        activeMemberships={[]}
      />,
    );

    getByTestId('active-memberships');
    const activeMemberships = getByTestId('active-memberships');

    expect(Number(activeMemberships.dataset.activeCount)).toEqual(0);

    getByText('Members');
  });

  it('should render with memberships', () => {
    const { getByText, getByTestId } = render(
      <ChatChannelMembershipSection
        pendingMemberships={[{ name: 'Ben', username: 'ben' }]}
        requestedMemberships={[
          { name: 'Peter', username: 'peter' },
          { name: 'Jess', username: 'jess' },
          { name: 'Xenox', username: 'xenox1' },
        ]}
        activeMemberships={[
          { name: 'Bobby', username: 'bobby' },
          { name: 'Sarah', username: 'sarah' },
        ]}
        currentMembershipRole="mod"
      />,
    );

    getByTestId('active-memberships');
    const activeMemberships = getByTestId('active-memberships');

    expect(Number(activeMemberships.dataset.activeCount)).toEqual(2);

    getByText('Members', {
      selector: '[data-testid="active-memberships"] *',
    });

    const pendingMemberships = getByTestId('pending-memberships');

    expect(Number(pendingMemberships.dataset.pendingCount)).toEqual(1);

    getByText('Pending Invitations', {
      selector: '[data-testid="pending-memberships"] *',
    });

    const requestedMemberships = getByTestId('requested-memberships');

    expect(Number(requestedMemberships.dataset.requestedCount)).toEqual(3);

    getByText('Joining Request', {
      selector: '[data-testid="requested-memberships"] *',
    });
  });
});
