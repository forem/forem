import { h } from 'preact';
import render from 'preact-render-to-json';
import { LoadingArticle } from '..';

describe('<LoadingArticle />', () => {
  it('should render', () => {
    const tree = render(<LoadingArticle />);

    expect(tree).toMatchSnapshot();
  });
});
