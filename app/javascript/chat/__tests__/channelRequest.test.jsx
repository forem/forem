import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import ChannelRequest from '../channelRequest';

const data = {
  user: {
    name: 'Sarthak',
  },
  channel: {
    name: 'IronMan',
  },
};

const getChannelRequest = (resource) => <ChannelRequest resource={resource} />;

describe('<Message />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getChannelRequest(data));
    expect(tree).toMatchSnapshot();
  });

  it('should have the proper elements, attributes and values', () => {
    const context = shallow(getChannelRequest(data));

    expect(context.find('.joining-message').exists()).toEqual(true);
  });
});
