import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import Content from '../content';

const getContent = () => (
  <Content
    onTriggerContent={false}
    resource={{ type_of: 'loading-user' }}
    activeChannelId={12345}
    pusherKey="ASDFGHJKL"
    githubToken=""
  />
);

describe('<Content />', () => {
  describe('as loading-user', () => {
    it('should render and test snapshot', () => {
      const tree = render(getContent());
      expect(tree).toMatchSnapshot();
    });
    it('should have proper elements, attributes and content', () => {
      const context = shallow(getContent());
      expect(
        context.find('.activechatchannel__activecontent').exists(),
      ).toEqual(true);
      const exitButton = context.find(
        '.activechatchannel__activecontentexitbutton',
      );
      expect(exitButton.exists()).toEqual(true);
      expect(exitButton.attr('data-content')).toEqual('exit');
      expect(exitButton.text()).toEqual('×');
    });
  });
  /*
  testing only as loading user since components that Content uses
  are independently tested
  */
});
