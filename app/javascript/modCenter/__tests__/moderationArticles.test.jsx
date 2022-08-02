import { h } from 'preact';
import { render, fireEvent, waitFor } from '@testing-library/preact';
import { ModerationArticles } from '../moderationArticles';
import '@testing-library/jest-dom';

const getTestArticles = () => {
  const articles = [
    {
      id: 1,
      title: 'An article title',
      path: 'an-article-title-di3',
      published_at: '2019-06-22T16:11:10.590Z',
      cached_tag_list: 'discuss, javascript, beginners',
      user: {
        articles_count: 1,
        name: 'hello',
        id: 1,
      },
    },
    {
      id: 2,
      title:
        'An article title that is quite very actually rather extremely long with all things considered',
      path: 'an-article-title-that-is-quite-very-actually-rather-extremely-long-with-all-things-considered-fi8',
      published_at: '2019-06-24T09:32:10.590Z',
      cached_tag_list: '',
      user: {
        articles_count: 3,
        name: 'howdy',
        id: 2,
      },
    },
  ];
  return JSON.stringify(articles);
};

describe('<ModerationArticles />', () => {
  beforeEach(() => {
    render(
      <div
        class="mod-index-list"
        id="mod-index-list"
        data-articles={getTestArticles()}
      >
        <div
          data-testid="flag-user-modal-container"
          class="flag-user-modal-container hidden"
        />
      </div>,
    );
  });

  it('renders a list of 2 articles', () => {
    render(<ModerationArticles />);

    const listOfArticles = document.querySelectorAll(
      '[data-testid^="mod-article-"]',
    );
    expect(listOfArticles.length).toEqual(2);
  });

  it('renders the iframes on click', async () => {
    const { getByTestId } = render(<ModerationArticles />);
    const singleArticle = getByTestId('mod-article-1');
    const summarySection = singleArticle.getElementsByTagName('summary')[0];
    summarySection.click();
    await waitFor(() => {
      const iframes = singleArticle.getElementsByTagName('iframe');
      expect(iframes.length).toEqual(2);
    });
  });

  it('toggles the "opened" class when opening or closing an article', async () => {
    const { getByTestId } = render(<ModerationArticles />);
    const singleArticle = getByTestId('mod-article-2');
    const summarySection = singleArticle.getElementsByTagName('summary')[0];

    fireEvent.click(summarySection);
    await waitFor(() => {
      expect(
        singleArticle.getElementsByClassName('article-iframes-container')[0]
          .classList,
      ).toContain('opened');
    });

    fireEvent.click(summarySection);
    await waitFor(() => {
      expect(
        singleArticle.getElementsByClassName('article-iframes-container')[0]
          .classList,
      ).not.toContain('opened');
    });
  });
});
