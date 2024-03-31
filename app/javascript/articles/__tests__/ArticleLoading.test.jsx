import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { LoadingArticle } from '..';

describe('<LoadingArticle />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<LoadingArticle />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { queryByTitle } = render(<LoadingArticle />);

    expect(queryByTitle('Loading posts...')).toExist();
  });
});
