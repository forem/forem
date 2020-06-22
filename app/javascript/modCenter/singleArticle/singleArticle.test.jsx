import { h } from 'preact';
import { axe } from 'jest-axe';
import { render, getNodeText } from '@testing-library/preact';

import SingleArticle from './index';

const article = {
  id: 1,
  title: 'An article title',
  path: 'an-article-title-di3',
  publishedAt: '',
  cachedTaglist: 'discuss, javascript, beginners',
  user: {
    articles_count: 1,
    name: 'hello',
  },
};

describe('<SingleArticle />', () => {
  const renderSingleArticle = () =>
    render(
      <SingleArticle
        id="1"
        title="An article title"
        path="an-article-title-di3"
        publishedAt="2019-06-28T16:11:10.590Z" // renders as Jun 28
        cachedTagList="discuss, javascript, beginners"
        user={article.user}
      />,
    );

  it('should have no a11y  violations', async () => {
    const { container } = renderSingleArticle();
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('renders the article title', () => {
    const { getByText } = renderSingleArticle();
    getByText(article.title);
  });

  it('renders the tags', () => {
    const { getByText } = renderSingleArticle();
    getByText('discuss');
    getByText('javascript');
    getByText('beginners');
  });
  it('renders the author name', () => {
    const { container } = renderSingleArticle();
    const text = getNodeText(container.querySelector('.article-author'));
    expect(text).toContain(article.user.name);
  });
  it('renders the hand wave emoji if the author has less than 3 articles ', () => {
    const { container } = renderSingleArticle();
    const text = getNodeText(container.querySelector('.article-author'));
    expect(text).toContain('👋');
  });
  it('renders the a formatted published date', () => {
    const { getByText } = renderSingleArticle();
    getByText('Jun 28');
  });
  it('renders the iframes on click', () => {
    const { container } = renderSingleArticle();
    container.querySelector('button.moderation-single-article').click();
    const iframes = container.querySelectorAll('iframe');
    expect(iframes.length).toEqual(2);

    const [articleIframe, actionPanelIframe] = iframes;
    expect(articleIframe.src).toContain(article.path);
    expect(actionPanelIframe.src).toContain(`${article.path}/actions_panel`);
  });
});
