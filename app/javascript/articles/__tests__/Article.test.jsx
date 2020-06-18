import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Article } from '..';
import {
  article,
  articleWithOrganization,
  articleWithSnippetResult,
  articleWithReactions,
  videoArticle,
  articleWithComments,
  podcastArticle,
  podcastEpisodeArticle,
  userArticle,
  assetPath,
} from './utilities/articleUtilities';
import '../../../assets/javascripts/lib/xss';
import '../../../assets/javascripts/utilities/timeAgo';

const commonProps = {
  reactionsIcon: assetPath('reactions-stack.png'),
  commentsIcon: assetPath('comments-bubble.png'),
  videoIcon: assetPath('video-camera.svg'),
};

describe('<Article /> component', () => {
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
    const { getByTestId, getByAltText } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={article}
        currentTag="javascript"
      />,
    );

    getByTestId('article-62407');
    getByAltText('Emil99 profile');
  });

  it('should render a featured article', () => {
    const { getByTestId, getByAltText } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        isFeatured
        article={article}
        currentTag="javascript"
      />,
    );

    getByTestId('featured-article');
    getByAltText('Emil99 profile');
  });

  it('should render a featured article for an organization', () => {
    const { getByTestId, getByAltText } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        isFeatured
        article={articleWithOrganization}
        currentTag="javascript"
      />,
    );

    getByTestId('featured-article');
    getByAltText('Web info-mediaries logo');
    getByAltText('Emil99 profile');
  });

  it('should render a featured article for a video post', () => {
    const { getByTitle } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        isFeatured
        article={videoArticle}
        currentTag="javascript"
      />,
    );

    getByTitle(/video duration/i);
  });

  it('should render with an organization', () => {
    const { getByAltText } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={articleWithOrganization}
        currentTag="javascript"
      />,
    );

    getByAltText('Web info-mediaries logo');
    getByAltText('Emil99 profile');
  });

  it('should render with a flare tag', () => {
    const { getByText } = render(
      <Article {...commonProps} isBookmarked={false} article={article} />,
    );

    getByText('#javascript', { selector: 'span' });
  });

  it('should render with a snippet result', () => {
    const { getByText } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={articleWithSnippetResult}
      />,
    );

    getByText(
      '…copying Rest withdrawal Handcrafted multi-state Pre-emptive e-markets feed...overriding RSS Fantastic Plastic Gloves invoice productize systemic Monaco…',
    );
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

    expect(reactions.textContent).toEqual('232 reactions');
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

    expect(comments.textContent).toEqual('213 comments');
  });

  it('should render with an add comment button when there are no comments', () => {
    const { getByTestId } = render(
      <Article {...commonProps} isBookmarked={false} article={article} />,
    );

    getByTestId('add-a-comment');
  });

  it('should render as saved on reading list', () => {
    const { getByText } = render(
      <Article {...commonProps} isBookmarked article={articleWithComments} />,
    );

    getByText('Saved', { selector: 'button' });
  });

  it('should render as not saved on reading list', () => {
    const { getByText } = render(
      <Article {...commonProps} isBookmarked={false} article={article} />,
    );

    getByText('Save', { selector: 'button' });
  });

  it('should render a video article', () => {
    const { getByTitle } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={videoArticle}
        currentTag="javascript"
      />,
    );

    getByTitle(/video duration/i);
  });

  it('should render a podcast article', () => {
    const { getByAltText, getByText } = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={podcastArticle}
      />,
    );

    getByAltText('Rubber local');
    getByText('podcast', { selector: 'span' });
  });

  it('should render a podcast episode', () => {
    const { getByText } = render(
      <Article isBookmarked={false} article={podcastEpisodeArticle} />,
    );

    getByText('podcast', { selector: 'span' });
  });

  it('should render a user article', () => {
    const { getByText } = render(<Article article={userArticle} />);

    getByText('person', { selector: 'span' });
  });
});
