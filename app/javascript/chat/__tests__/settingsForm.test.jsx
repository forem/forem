import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import SettingsForm from '../ChatChannelSettings/SettingsForm';

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
  it('should render and test snapshot', () => {
    const tree = render(getSettingsForm(data));
    expect(tree).toMatchSnapshot();
  });

  it('should render the the component', () => {
    const context = shallow(getSettingsForm(data));

    expect(context.find('.settings-section').exists()).toEqual(true);
  });
});
