import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { InviteForm } from '../ChatChannelSettings/InviteForm';

describe('<InviteForm />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<InviteForm invitationUsernames="" />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render with no usernames', () => {
    const { queryByLabelText, queryByText } = render(
      <InviteForm invitationUsernames="" />,
    );

    expect(queryByLabelText('Usernames to invite')).toBeDefined();
    expect(queryByText('Submit')).toBeDefined();
  });

  it('should render with usernames to invite', () => {
    const { getByLabelText } = render(
      <InviteForm invitationUsernames="@bobbytables, @xss, @owasp" />,
    );

    const input = getByLabelText('Usernames to invite');

    expect(input.value).toEqual('@bobbytables, @xss, @owasp');
  });
});
