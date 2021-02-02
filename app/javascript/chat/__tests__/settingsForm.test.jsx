import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { SettingsForm } from '../ChatChannelSettings/SettingsForm';

const data = {
  channelDescription: 'some description test',
  channelDiscoverable: true,
};

const getSettingsForm = (channelDetails) => {
  return (
    <SettingsForm
      showGlobalBadgeNotification={channelDetails.showGlobalBadgeNotification}
    />
  );
};

describe('<SettingsForm />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(getSettingsForm(data));
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render the the component', () => {
    const { queryByText, queryByLabelText } = render(getSettingsForm(data));

    // title
    expect(queryByText('Channel Settings')).toBeDefined();

    // description of channel
    expect(queryByLabelText('Description')).toBeDefined();

    // whether or not the channel is discoverable
    expect(queryByLabelText('Channel Discoverable')).toBeDefined();

    // submit buttton
    expect(queryByText('Submit')).toBeDefined();
  });
});
