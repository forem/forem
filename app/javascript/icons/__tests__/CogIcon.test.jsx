import { h } from 'preact';
import render from 'preact-render-to-json';
import { CogIcon } from '../CogIcon';

describe('<CommentSubscription />', () => {
  it('should render', () => {
    const tree = render(<CogIcon />);

    expect(tree).toMatchSnapshot();
  });
});
