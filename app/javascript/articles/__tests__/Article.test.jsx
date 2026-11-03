/* eslint-disable no-irregular-whitespace */
import { h } from 'preact';
import { render, fireEvent, waitFor } from '@testing-library/preact';
import { axe } from 'jest-axe';
import '@testing-library/jest-dom';
import { Article } from '..';
import { reactionImagesSupport } from '../../__support__/reaction_images';
import { locale } from '../../utilities/locale';
import {
  article,
  articleWithOrganization,
  articleWithSnippetResult,
  articleWithReactions,
  videoArticle,
  articleWithComments,
  articleWithCommentWithLongParagraph,
  podcastArticle,
  podcastEpisodeArticle,
  userArticle,
  quickieArticle,
  assetPath,
} from './utilities/articleUtilities';
import '../../../assets/javascripts/lib/xss';
import '../../../assets/javascripts/utilities/timeAgo';

const commonProps = {
  commentsIcon: assetPath('comments-bubble.png'),
  videoIcon: assetPath('video-camera.svg'),
};

describe('<Article /> component', () => {
  beforeAll(() => {
    reactionImagesSupport();
  });

  it('should have no a11y violations for a standard article', async () => {
    const { container } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={article}
        currentTag="javascript"
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations for a featured article', async () => {
    const { container } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        isFeatured
        article={article}
        currentTag="javascript"
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render a standard article', () => {
    const { container, queryByAltText } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={article}
        currentTag="javascript"
      />,
    );

    expect(container.firstChild).not.toHaveClass('crayons-story--featured', {
      exact: false,
    });
    expect(queryByAltText('Emil99 profile')).toExist();
  });

  it('should render a featured article', () => {
    const { container, queryByAltText } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        isFeatured
        article={article}
        currentTag="javascript"
      />,
    );

    expect(container.firstChild).toHaveClass('crayons-story--featured', {
      exact: false,
    });
    expect(queryByAltText('Emil99 profile')).toExist();
  });

  it('should render a rich feed', () => {
    const tree = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        isFeatured
        feedStyle="rich"
        article={article}
        currentTag="javascript"
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render a featured article for an organization', () => {
    const { container, queryByAltText } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        isFeatured
        article={articleWithOrganization}
        currentTag="javascript"
      />,
    );

    expect(container.firstChild).toHaveClass('crayons-story--featured', {
      exact: false,
    });
    expect(queryByAltText('Web info-mediaries logo')).toExist();
    expect(queryByAltText('Emil99 profile')).toExist();
  });

  it('should render a featured article for a video post', () => {
    const { queryByTitle } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        isFeatured
        article={videoArticle}
        currentTag="javascript"
      />,
    );

    expect(queryByTitle(/video duration/i)).toExist();
  });

  it('should render with an organization', () => {
    const { queryByAltText } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={articleWithOrganization}
        currentTag="javascript"
      />,
    );

    expect(queryByAltText('Web info-mediaries logo')).toExist();
    expect(queryByAltText('Emil99 profile')).toExist();
  });

  it('should render with a flare tag', () => {
    const { queryByText } = render(
      <Article {...commonProps} isBookmarked={false} article={article} />,
    );

    expect(queryByText('#javascript', { selector: 'span' })).toBeDefined();
  });

  it('should render with a snippet result', () => {
    const { queryByText } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={articleWithSnippetResult}
      />,
    );

    expect(
      queryByText(
        '…copying Rest withdrawal Handcrafted multi-state Pre-emptive e-markets feed...overriding RSS Fantastic Plastic Gloves invoice productize systemic Monaco…',
      ),
    ).toExist();
  });

  it('should render with reactions', () => {
    const { getByTitle } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={articleWithReactions}
      />,
    );

    const reactions = getByTitle('Number of reactions');

    expect(reactions.textContent).toEqual(`232 ${locale('core.reaction')}s`);
  });

  it('should render with comments', () => {
    const { getByTitle } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={articleWithComments}
      />,
    );

    const comments = getByTitle('Number of comments');

    expect(comments.textContent).toEqual(`213 ${locale('core.comment')}s`);
  });

  it('should render second paragraph, but not third', () => {
    const { queryByTestId } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={articleWithComments}
      />,
    );

    const comments = queryByTestId('comment-content');

    expect(comments.textContent).toContain('Kitsch hoodie artisan');
    expect(comments.classList).not.toContain('Third paragraph');
  });

  it('should render the first part of a long paragraph', () => {
    const { queryByTestId } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={articleWithCommentWithLongParagraph}
      />,
    );

    const comments = queryByTestId('comment-content');

    expect(comments.textContent).toContain('Start of paragraph');
    expect(comments.classList).not.toContain('End of paragraph');
  });

  it('should render with an add comment button when there are no comments', () => {
    const { queryByTestId } = render(
      <Article {...commonProps} isBookmarked={false} article={article} />,
    );

    expect(queryByTestId('add-a-comment')).toExist();
  });

  it('should render as saved on reading list', () => {
    const { queryByText } = render(
      <Article {...commonProps} isBookmarked article={articleWithComments} />,
    );

    expect(queryByText('Saved', { selector: 'button' })).toBeDefined();
  });

  it('should render as not saved on reading list', () => {
    const { queryByText } = render(
      <Article {...commonProps} isBookmarked={false} article={article} />,
    );

    expect(queryByText('Save', { selector: 'button' })).toBeDefined();
  });

  it('should render a video article', () => {
    const { queryByTitle } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={videoArticle}
        currentTag="javascript"
      />,
    );

    expect(queryByTitle(/video duration/i)).toExist();
  });

  it('should render a podcast article', () => {
    const { queryByAltText, queryByText } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={podcastArticle}
      />,
    );

    expect(queryByAltText('Rubber local')).toExist();
    expect(queryByText('podcast', { selector: 'span' })).toExist();
  });

  it('should render a podcast episode', () => {
    const { queryByText } = render(
      <Article isBookmarked={false} article={podcastEpisodeArticle} />,
    );

    expect(queryByText('podcast', { selector: 'span' })).toExist();
  });

  it('should render a user article', () => {
    const { queryByText } = render(<Article article={userArticle} />);

    expect(queryByText('person', { selector: 'span' })).toExist();
  });

  it('should show bookmark button when article is saveable', () => {
    const { queryByTestId } = render(
      <Article {...commonProps} isBookmarked={false} article={article} saveable={true} />,
    );

    expect(queryByTestId(`article-save-button-${article.id}`)).toBeDefined();
  });

  it('should hide bookmark button when article is not saveable', () => {
    const { queryByTestId } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={article}
        saveable={false}
      />,
    );

    expect(queryByTestId(`article-save-button-${article.id}`)).toBeNull();
  });

  describe('Quickie (status) feed card UX & inline interactions', () => {
    beforeEach(() => {
      global.getCsrfToken = jest.fn(() => Promise.resolve('test-csrf-token'));
    });

    afterEach(() => {
      delete global.getCsrfToken;
      delete global.sendFetch;
    });

    it('renders elevated quickie card with badge, author handle, formatted body, and no a11y violations', async () => {
      const { container, getByTestId, getByText } = render(
        <Article
          {...commonProps}
          isBookmarked={false}
          article={quickieArticle}
          currentUserId={999}
          bookmarkClick={jest.fn()}
          saveable
        />,
      );

      expect(container.firstChild).toHaveClass('crayons-story--status');
      expect(getByTestId('quickie-badge')).toHaveTextContent('Quickie');
      expect(getByText('@Emil99')).toBeInTheDocument();
      expect(
        getByText('Shipped a new zero-copy parser in Rust today.'),
      ).toBeInTheDocument();
      expect(
        getByText('Deep Dive into Zero-Copy Parsing'),
      ).toBeInTheDocument();
      expect(getByTestId('quickie-reaction-button')).toBeInTheDocument();

      const results = await axe(container);
      expect(results).toHaveNoViolations();
    });

    it('allows reacting inline on a quickie directly from the home feed via the reaction button and picker', async () => {
      global.sendFetch = jest.fn(() =>
        jest.fn(() =>
          Promise.resolve({
            status: 200,
            json: () => Promise.resolve({ result: 'create', category: 'unicorn' }),
          }),
        ),
      );

      const { getByTestId, getByTitle } = render(
        <Article
          {...commonProps}
          isBookmarked={false}
          article={quickieArticle}
          currentUserId={999}
          bookmarkClick={jest.fn()}
          saveable
        />,
      );

      const reactionWrapper = getByTestId('quickie-reaction-button').parentElement;
      fireEvent.mouseEnter(reactionWrapper);

      expect(getByTestId('quickie-reaction-picker')).toBeInTheDocument();

      fireEvent.click(getByTestId('quickie-react-unicorn'));

      await waitFor(() => {
        expect(global.sendFetch).toHaveBeenCalledWith(
          'reaction-creation',
          expect.any(FormData),
        );
      });

      expect(getByTitle('Number of reactions').textContent).toEqual(
        `1\u00a0${locale('core.reaction')}`,
      );
      expect(getByTestId('quickie-reaction-button')).toHaveClass('is-reacted');
    });

    it('allows commenting inline on a quickie and appends the new reply to the card thread', async () => {
      global.sendFetch = jest.fn(() =>
        jest.fn(() =>
          Promise.resolve({
            status: 200,
            json: () =>
              Promise.resolve({
                status: 'created',
                id: 777,
                id_code: '1d9',
                url: 'http://example.com/emil99/shipped-zero-copy-parser-123#comment-1d9',
                body_html: '<p>Awesome benchmark numbers!</p>',
                published_timestamp: '2026-11-03T14:00:00Z',
                user: {
                  id: 999,
                  username: 'dev_tester',
                  name: 'Dev Tester',
                  profile_pic: '/images/10.png',
                },
              }),
          }),
        ),
      );

      const { getByTestId, queryByTestId, getByText, getByTitle } = render(
        <Article
          {...commonProps}
          isBookmarked={false}
          article={quickieArticle}
          currentUserId={999}
          bookmarkClick={jest.fn()}
          saveable
        />,
      );

      expect(queryByTestId('quickie-comment-form')).toBeNull();

      // Open the inline reply drawer
      fireEvent.click(getByTestId('add-a-comment'));
      expect(getByTestId('quickie-comment-form')).toBeInTheDocument();

      const textarea = getByTestId('quickie-comment-textarea');
      fireEvent.input(textarea, {
        target: { value: 'Awesome benchmark numbers!' },
      });

      fireEvent.click(getByTestId('quickie-comment-submit'));

      await waitFor(() => {
        expect(global.sendFetch).toHaveBeenCalledWith(
          'comment-creation',
          JSON.stringify({
            comment: {
              body_markdown: 'Awesome benchmark numbers!',
              commentable_id: quickieArticle.id,
              commentable_type: 'Article',
            },
          }),
        );
      });

      await waitFor(() => {
        expect(getByText('Awesome benchmark numbers!')).toBeInTheDocument();
        expect(getByText('Dev Tester')).toBeInTheDocument();
      });

      expect(getByTitle('Number of comments').textContent).toEqual(
        `1\u00a0${locale('core.comment')}`,
      );
    });
  });
});
