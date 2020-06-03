import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import Content from '../content';

const data = [
  {
    onTriggerContent: false,
    resource: { type_of: 'channel-request' },
    activeChannelId: 12345,
    pusherKey: 'ASDFGHJKL',
    githubToken: '',
  },
  {
    onTriggerContent: false,
    resource: { type_of: 'loading-user' },
    activeChannelId: 1235,
    pusherKey: 'ASDFGHJKL',
    githubToken: '',
  },
];

const getContent = (resource) => <Content resource={resource} />;

describe('<Content />', () => {
  describe('as loading-user', () => {
    it('should render and test snapshot', () => {
      const tree = render(getContent(data[0]));
      expect(tree).toMatchSnapshot();
    });
    it('should have proper elements, attributes and content', () => {
      const context = shallow(getContent(data[0]));
      expect(
        context.find('.activechatchannel__activecontent').exists(),
      ).toEqual(true);
    });
  });
  describe('as channel-request', () => {
    it('should render and test snapshot', () => {
      const tree = render(getContent(data[1]));
      expect(tree).toMatchSnapshot();
    });
    it('should have proper elements, attributes and content', () => {
      const context = shallow(getContent(data[1]));
      expect(
        context.find('.activechatchannel__activecontent').exists(),
      ).toEqual(true);
    });
  });
  /*
  testing only as loading user since components that Content uses
  are independently tested
  */
});
