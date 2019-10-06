import { h } from 'preact';
import { shallow } from 'preact-render-spy';
import { render } from 'preact-render-to-json';
import OnboardingSingleTag from '../OnboardingSingleTag';

describe('<OnboardingSingleTag />', () => {
  const followingTag = { following: true, name: 'JavaScript' };
  const notFollowingTag = { following: false, name: 'Go' };

  describe('when given a following tag', () => {
    it('renders correctly', () => {
      const context = render(<OnboardingSingleTag tag={followingTag} />);
      expect(context).toMatchSnapshot();
    });

    it('responses to clicks', () => {
      const onClick = jest.fn();
      const context = shallow(
        <OnboardingSingleTag tag={followingTag} onTagClick={onClick} />,
      );
      expect(context.find('a').text()).toEqual('#JavaScript✓');
      context.find('.onboarding-tag-link-follow').simulate('click');
      expect(onClick).toHaveBeenCalledTimes(1);
      context.render(
        <OnboardingSingleTag tag={notFollowingTag} onTagClick={onClick} />,
      );
      expect(context.find('a').text()).toEqual('#Go+');
    });
  });

  describe('when given a non-following tag', () => {
    it('renders correctly', () => {
      const context = render(<OnboardingSingleTag tag={notFollowingTag} />);
      expect(context).toMatchSnapshot();
    });

    it('responses to clicks', () => {
      const onClick = jest.fn();
      const context = shallow(
        <OnboardingSingleTag tag={notFollowingTag} onTagClick={onClick} />,
      );
      expect(context.find('a').text()).toEqual('#Go+');
      context.find('.onboarding-tag-link-follow').simulate('click');
      expect(onClick).toHaveBeenCalledTimes(1);
      context.render(
        <OnboardingSingleTag tag={followingTag} onTagClick={onClick} />,
      );
      expect(context.find('a').text()).toEqual('#JavaScript✓');
    });
  });
});
