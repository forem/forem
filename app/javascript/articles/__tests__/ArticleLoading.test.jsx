import { h } from 'preact';
import { render } from '@testing-library/preact';
import { LoadingArticle } from '..';

describe('<LoadingArticle />', () => {
  it('should render', () => {
    const { getByTitle } = render(<LoadingArticle />);

    getByTitle('Loading posts...');
  });
});
