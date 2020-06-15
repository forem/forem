import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import PersonalSettng from '../ChatChannelSettings/PersonalSetting';

const data = {
  showGlobalBadgeNotification: true,
};

const getPersonalSettng = (channelDetails) => {
  return (
    <PersonalSettng
      showGlobalBadgeNotification={channelDetails.showGlobalBadgeNotification}
    />
  );
};

describe('<PersonalSettng />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getPersonalSettng(data));

    expect(tree).toMatchSnapshot();
  });

  it('should render the the component', () => {
    const context = shallow(getPersonalSettng(data));

    expect(context.find('.personl-settings').exists()).toEqual(true);
  });
});
