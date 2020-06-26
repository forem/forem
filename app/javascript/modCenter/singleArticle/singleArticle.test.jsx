import { h } from 'preact';
import { axe } from 'jest-axe';
import { render, getNodeText, fireEvent } from '@testing-library/preact';

import SingleArticle from './index';

const testArticle = {
  id: 1,
  title: 'An article title',
  path: 'an-article-title-di3',
  publishedAt: '2019-06-22T16:11:10.590Z',
  cachedTagList: 'discuss, javascript, beginners',
  user: {
    articles_count: 1,
    name: 'hello',
  },
};

describe('<SingleArticle />', () => {
  const renderSingleArticle = (article = testArticle) =>
    render(
      <SingleArticle
        id={article.title}
        title={article.title}
        path={article.path}
        publishedAt={article.publishedAt} // renders as Jun 28
        cachedTagList={article.cachedTagList}
        user={article.user}
      />,
    );

  it('should have no a11y  violations', async () => {
    const { container } = renderSingleArticle();
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('renders the article title', () => {
    const { queryByText } = renderSingleArticle();

    expect(queryByText(testArticle.title)).toBeDefined();
  });

  it('renders the tags', () => {
    const { queryByText } = renderSingleArticle();

    expect(queryByText('discuss')).toBeDefined();
    expect(queryByText('javascript')).toBeDefined();
    expect(queryByText('beginners')).toBeDefined();
  });

  it('renders the author name', () => {
    const { container } = renderSingleArticle();
    const text = getNodeText(container.querySelector('.article-author'));
    expect(text).toContain(testArticle.user.name);
  });

  it('renders the hand wave emoji if the author has less than 3 articles ', () => {
    const { container } = renderSingleArticle();
    const text = getNodeText(container.querySelector('.article-author'));
    expect(text).toContain('👋');
  });

  it('renders the correct formatted published date', () => {
    const { queryByText } = renderSingleArticle();

    expect(queryByText('Jun 22')).toBeDefined();
  });

  it('renders the correct formatted published date as a time if the date is the same day', () => {
    const today = new Date();
    today.setSeconds('00');
    testArticle.publishedAt = today.toISOString();

    const { queryByText } = renderSingleArticle(testArticle);
    const readableTime = today.toLocaleTimeString().replace(':00 ', ' '); // looks like 8:05 PM

    expect(queryByText(readableTime)).toBeDefined();
  });

  it('renders the iframes on click', () => {
    const { container } = renderSingleArticle();
    container.querySelector('button.moderation-single-article').click();
    const iframes = container.querySelectorAll('iframe');
    expect(iframes.length).toEqual(2);

    const [articleIframe, actionPanelIframe] = iframes;
    expect(articleIframe.src).toContain(testArticle.path);
    expect(actionPanelIframe.src).toContain(
      `${testArticle.path}/actions_panel`,
    );
  });

  it('adds the opened class when opening an article', () => {
    const toggleArticle = jest.fn();
    const { container } = render(
      <SingleArticle
        id={testArticle.title}
        title={testArticle.title}
        path={testArticle.path}
        publishedAt={testArticle.publishedAt} // renders as Jun 28
        cachedTagList={testArticle.cachedTagList}
        user={testArticle.user}
        toggleArticle={toggleArticle}
      />,
    );
    fireEvent.click(
      container.querySelector('button.moderation-single-article'),
    );

    expect(
      container.querySelector('.article-iframes-container').classList,
    ).toContain('opened');
  });
});
