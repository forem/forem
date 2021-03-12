import { h } from 'preact';
import { render } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import { axe } from 'jest-axe';
import { Article } from '../article';

global.fetch = fetch;

const getArticle = () => {
  return {
    title: 'Your approval means nothing to me',
    type_of: 'article',
    path: '/princesscarolyn/your-approval-means-nothing-to-me-42640',
  };
};

describe('<Article />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(<Article resource={getArticle()} />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', async () => {
    const { queryByTitle } = render(<Article resource={getArticle()} />);

    expect(queryByTitle('Your approval means nothing to me')).toBeDefined();
  });
});
