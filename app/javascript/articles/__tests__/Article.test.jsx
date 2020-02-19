import { h } from 'preact';
import render from 'preact-render-to-json';
import { Article } from '..';
import {
  article,
  articleWithOrganization,
  articleWithSnippetResult,
  articleWithReadingTimeGreaterThan1,
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
  it('should render a standard article', () => {
    const tree = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={article}
        currentTag="javascript"
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render with an organization', () => {
    const tree = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={articleWithOrganization}
        currentTag="javascript"
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render with a flare tag', () => {
    const tree = render(
      <Article {...commonProps} isBookmarked={false} article={article} />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render with a snippet result', () => {
    const tree = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={articleWithSnippetResult}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render with a reading time', () => {
    const tree = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={articleWithReadingTimeGreaterThan1}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render with reactions', () => {
    const tree = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={articleWithReactions}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render with comments', () => {
    const tree = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={articleWithComments}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render as saved on reading list', () => {
    const tree = render(
      <Article {...commonProps} isBookmarked article={articleWithComments} />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render a video article', () => {
    const tree = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={videoArticle}
        currentTag="javascript"
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render a video article with a flare tag', () => {
    const tree = render(
      <Article {...commonProps} isBookmarked={false} article={videoArticle} />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render a podcast article', () => {
    const tree = render(
      <Article
        {...commonProps}
        isBookmarked={false}
        article={podcastArticle}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render a podcast episode', () => {
    const tree = render(
      <Article isBookmarked={false} article={podcastEpisodeArticle} />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('should render a user article', () => {
    const tree = render(<Article article={userArticle} />);
    expect(tree).toMatchSnapshot();
  });
});
