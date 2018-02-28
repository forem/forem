import { h } from 'preact';
import render from 'preact-render-to-json';
import OnboardingFollowTags from '../OnboardingFollowTags';

describe('<OnboardingFollowTags />', () => {
  it('renders properly when given a tag', () => {
    const userData = {};
    const allTags = [{
      bg_color_hex: '#000000',
      id: 715,
      name: 'discuss',
      text_color_hex: '#ffffff',
    }, {
      bg_color_hex: '#f7df1e',
      id: 6,
      name: 'javascript',
      text_color_hex: '#000000',
    }, {
      bg_color_hex: '#f7df1e',
      id: 6,
      name: 'javascript',
      text_color_hex: '#000000',
    }];
    const followedTags = {};
    const handleFollowTag = jest.fn();
    const tree = render(<OnboardingFollowTags
      userData={userData}
      allTags={allTags}
      followedTags={followedTags}
      handleFollowTag={handleFollowTag}
    />);
    expect(tree).toMatchSnapshot();
  });
});
