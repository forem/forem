import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { PersonalSettng } from '../ChatChannelSettings/PersonalSetting';

describe('<PersonalSettng />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <PersonalSettng showGlobalBadgeNotification />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render the the component', () => {
    const { queryByText, queryByLabelText } = render(
      <PersonalSettng showGlobalBadgeNotification />,
    );

    // get the section header
    expect(queryByText('Personal Settings')).toBeDefined();

    // get the subsection header
    expect(queryByText('Notifications')).toBeDefined();

    // form fields
    expect(
      queryByLabelText('Receive Notifications for New Messages'),
    ).toBeDefined();
    expect(queryByText('Submit', { selector: 'button' })).toBeDefined();
  });
});
