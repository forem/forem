import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import RequestManager from '../requestManager';

const data = [
  {
    id: 2,
    channel_name: 'ironman',
  },
];

const getRequestManager = (resource) => <RequestManager resource={resource} />;

describe('<RequestManager />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getRequestManager(data));
    expect(tree).toMatchSnapshot();
  });

  it('should have the proper elements, attributes and values', () => {
    const context = shallow(getRequestManager(data));

    expect(context.find('.request_manager_header').exists()).toEqual(true);
  });
});
