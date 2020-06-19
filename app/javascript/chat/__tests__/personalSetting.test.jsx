import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import PersonalSettng from '../ChatChannelSettings/PersonalSetting';

describe('<PersonalSettng />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <PersonalSettng showGlobalBadgeNotification />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render the the component', () => {
    const { getByText, getByLabelText } = render(
      <PersonalSettng showGlobalBadgeNotification />,
    );

    // get the section header
    getByText('Personal Settings');

    // get the subsection header
    getByText('Notifications');

    // form fields
    getByLabelText('Receive Notifications for New Messages');
    getByText('Submit', { selector: 'button' });
  });
});
