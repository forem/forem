import { h } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../common-prop-types/article-prop-types';
import {
  ArticleCoverImage,
  CommentsCount,
  CommentsList,
  ContentTitle,
  Meta,
  SaveButton,
  SearchSnippet,
  TagList,
  ReactionsCount,
  ReadingTime,
  Video,
} from './components';
import { PodcastArticle } from './PodcastArticle';

export const Article = ({
  article,
  isFeatured,
  isBookmarked,
  bookmarkClick,
  isRoot,
  feedStyle,
  pinned,
  saveable,
}) => {
  if (article && article.type_of === 'podcast_episodes') {
    return <PodcastArticle article={article} />;
  }

  const isArticle = article.class_name === 'Article';

  let showCover =
    (isFeatured || (feedStyle === 'rich' && article.main_image)) &&
    !article.cloudinary_video_url && !article.video;

  const parsedUrl = new URL(article.url);
  const domain = parsedUrl.hostname.replace(".forem.com", "").replace(".to", "");

  // pinned article can have a cover image
  showCover = showCover || (article.pinned && article.main_image);

  return (
    <article
      className={`crayons-story${
        isFeatured ? ' crayons-story--featured' : ''
      }`}
      id={isFeatured ? 'featured-story-marker' : `article-${article.id}`}
      data-feed-content-id={isArticle ? article.id : null}
      data-content-user-id={article.user_id}
      style={{ position: 'relative' }}
    >
      <a
        href={article.url}
        aria-labelledby={`article-link-${article.id}`}
        className="crayons-story__stretched-link"
        style={{
          position: 'absolute',
          top: 0,
          right: 0,
          bottom: 0,
          left: 0,
          zIndex: 1,
        }}
        onClick={(event) => {
          // Only intercept for InstantClick on normal clicks
          if (!(event.which > 1 || event.metaKey || event.ctrlKey || event.shiftKey)) {
            event.preventDefault();
            const fullUrl = article.url;
            InstantClick.preload(fullUrl);
            InstantClick.display(fullUrl);
          }
          // For modified clicks (ctrl/cmd/middle), browser handles naturally
        }}
      >
        <span className="sr-only">{article.title}</span>
      </a>
      <div>
        {article.video && <Video article={article} />}

        {showCover && <ArticleCoverImage article={article} />}
        <div className={`crayons-story__body crayons-story__body-${article.type_of}`} style={{ position: 'relative', zIndex: 2 }}>
          { article.context_note && article.context_note.length > 0 && (
              <a href={article.url} className="crayons-article__context-note crayons-article__context-note__feed" style={{ position: 'relative', zIndex: 2 }} dangerouslySetInnerHTML={{__html: article.context_note}} />
            )}
          <div className="crayons-story__top">
            {article.user && (
              <div style={{ position: 'relative', zIndex: 2 }}>
                <Meta article={article} organization={article.organization} />
              </div>
            )}
            {pinned && (
              <div
                className="pinned color-accent-brand fw-bold"
                data-testid="pinned-article"
              >
                {/* images/pin.svg */}
                <svg
                  aria-hidden="true"
                  className="mr-2 align-text-bottom color-accent-brand"
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  width="24"
                  height="24"
                >
                  <path d="M22.314 10.172l-1.415 1.414-.707-.707-4.242 4.242-.707 3.536-1.415 1.414-4.242-4.243-4.95 4.95-1.414-1.414 4.95-4.95-4.243-4.242 1.414-1.415L8.88 8.05l4.242-4.242-.707-.707 1.414-1.415z" />
                </svg>
                Pinned
                <span class="hidden s:inline">&nbsp;post</span>
              </div>
            )}
          </div>

          <div className="crayons-story__indention">
            <ContentTitle article={article} />
            {article.type_of !== 'status' && (
              <div style={{ position: 'relative', zIndex: 2 }}>
                <TagList tags={article.tag_list} flare_tag={article.flare_tag} />
              </div>
            )}

            {article.type_of === 'status' && article.body_preview && article.body_preview.length > 0 && (<div className='crayons-story__contentpreview text-styles' dangerouslySetInnerHTML={{__html: article.body_preview}} />)}

            {isArticle && (
              // eslint-disable-next-line no-underscore-dangle
              <SearchSnippet highlightText={article.highlight} />
            )}

            <div className="crayons-story__bottom">
              {(article.class_name !== 'User' && article.user) && (
                <div className="crayons-story__details" style={{ position: 'relative', zIndex: 2 }}>
                  <ReactionsCount article={article} />
                  <CommentsCount
                    count={article.comments_count}
                    articlePath={article.url}
                    articleTitle={article.title}
                  />
                </div>
              )}

              <div className="crayons-story__save" style={{ position: 'relative', zIndex: 2 }}>
                <ReadingTime readingTime={article.reading_time} typeOf={article.type_of} />
                { isRoot && (<small class="crayons-story__tertiary mr-2 fs-xs fw-bold">{domain}</small>)}
                <SaveButton
                  article={article}
                  isBookmarked={isBookmarked}
                  onClick={bookmarkClick}
                  saveable={saveable}
                />
              </div>
            </div>
          </div>
        </div>

        {article.top_comments && article.top_comments.length > 0 && (
          <div style={{ position: 'relative', zIndex: 2 }}>
            <CommentsList
              comments={article.top_comments}
              articlePath={article.url}
              totalCount={article.comments_count}
            />
          </div>
        )}
      </div>
    </article>
  );
};

Article.defaultProps = {
  isBookmarked: false,
  isFeatured: false,
  isRoot: false,
  feedStyle: 'basic',
  saveable: true,
};

Article.propTypes = {
  article: articlePropTypes.isRequired,
  isBookmarked: PropTypes.bool,
  isFeatured: PropTypes.bool,
  isRoot: PropTypes.bool,
  feedStyle: PropTypes.string,
  bookmarkClick: PropTypes.func.isRequired,
  pinned: PropTypes.bool,
  saveable: PropTypes.bool.isRequired,
};
