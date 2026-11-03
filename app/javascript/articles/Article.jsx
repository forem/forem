import { h } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../common-prop-types/article-prop-types';
import {
  ArticleCoverImage,
  CommentsCount,
  CommentsList,
  ContentTitle,
  FavoritedMarker,
  Meta,
  QuickieCommentSection,
  QuickieReactions,
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
  currentUserId,
  isFeatured,
  isBookmarked,
  bookmarkClick,
  isRoot,
  feedStyle,
  pinned,
  saveable,
}) => {
  const isStatus = article && article.type_of === 'status';
  const [isCommentOpen, setIsCommentOpen] = useState(false);
  const [localComments, setLocalComments] = useState(
    () => (article && article.top_comments) || [],
  );
  const [localCommentsCount, setLocalCommentsCount] = useState(
    () => (article && article.comments_count) || 0,
  );
  const [addedCommentsCount, setAddedCommentsCount] = useState(0);

  useEffect(() => {
    setLocalComments((article && article.top_comments) || []);
    setLocalCommentsCount((article && article.comments_count) || 0);
    setAddedCommentsCount(0);
    setIsCommentOpen(false);
  }, [article?.id, article?.comments_count, article?.top_comments]);

  if (article && article.type_of === 'podcast_episodes') {
    return <PodcastArticle article={article} />;
  }

  const handleCommentCreated = (newComment) => {
    setLocalComments((prev) => [newComment, ...(prev || [])]);
    setLocalCommentsCount((prev) => (prev || 0) + 1);
    setAddedCommentsCount((prev) => prev + 1);
    setIsCommentOpen(false);
  };

  const isArticle = article.class_name === 'Article';
  const clickableClassList = [
    'crayons-story',
    'crayons-story__top',
    'crayons-story__body',
    'crayons-story__indention',
    'crayons-story__title',
    'crayons-story__tags',
    'crayons-story__bottom',
    'crayons-story__tertiary',
  ];

  let showCover =
    (isFeatured || (feedStyle === 'rich' && article.main_image)) &&
    !article.cloudinary_video_url &&
    !article.video;

  let domain = '';
  if (article.url) {
    try {
      const parsedUrl = new URL(article.url, window.location.origin);
      domain = parsedUrl.hostname.replace('.forem.com', '').replace('.to', '');
    } catch (_e) {
      domain = '';
    }
  }

  // pinned article can have a cover image
  showCover = showCover || (article.pinned && article.main_image);

  return (
    <article
      className={`crayons-story cursor-pointer${
        isFeatured ? ' crayons-story--featured' : ''
      }${isStatus ? ' crayons-story--status' : ''}`}
      id={isFeatured ? 'featured-story-marker' : `article-${article.id}`}
      data-feed-content-id={isArticle ? article.id : null}
      data-content-user-id={article.user_id}
    >
      <a
        href={article.url}
        aria-labelledby={`article-link-${article.id}`}
        className="crayons-story__hidden-navigation-link"
      >
        {article.title}
      </a>
      <div
        role="presentation"
        onClick={(event) => {
          const { classList } = event.target;
          if (clickableClassList.includes(...classList)) {
            if (event.which > 1 || event.metaKey || event.ctrlKey) {
              // Indicates should open in _blank
              window.open(article.url, '_blank');
            } else {
              const fullUrl = article.url; // InstantClick deals with full urls
              InstantClick.preload(fullUrl);
              InstantClick.display(fullUrl);
            }
          }
        }}
      >
        {(article.video || article.cloudinary_video_url) && (
          <Video article={article} />
        )}

        {showCover && <ArticleCoverImage article={article} />}
        <div
          className={`crayons-story__body crayons-story__body-${article.type_of}`}
        >
          {article.context_note && article.context_note.length > 0 && (
            <a
              href={article.url}
              className="crayons-article__context-note crayons-article__context-note__feed"
              dangerouslySetInnerHTML={{ __html: article.context_note }}
            />
          )}
          <div className="crayons-story__top">
            {article.user && (
              <Meta article={article} organization={article.organization} />
            )}
            {isStatus && !pinned && (
              <span
                className="crayons-story__status-badge"
                data-testid="quickie-badge"
                title="Quickie status update"
              >
                <svg
                  width="12"
                  height="12"
                  viewBox="0 0 24 24"
                  aria-hidden="true"
                  className="crayons-story__status-badge-icon"
                >
                  <path d="M13 10h7l-9 13v-9H4l9-13z" />
                </svg>
                Quickie
              </span>
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
              <TagList tags={article.tag_list} flare_tag={article.flare_tag} />
            )}

            {article.type_of === 'status' &&
              article.body_preview &&
              article.body_preview.length > 0 && (
                <div
                  className="crayons-story__contentpreview text-styles"
                  dangerouslySetInnerHTML={{ __html: article.body_preview }}
                />
              )}

            {isArticle && (
              // eslint-disable-next-line no-underscore-dangle
              <SearchSnippet highlightText={article.highlight} />
            )}

            <div className="crayons-story__bottom">
              {article.class_name !== 'User' && article.user && (
                <div className="crayons-story__details">
                  {isStatus ? (
                    <QuickieReactions
                      article={article}
                      currentUserId={currentUserId}
                    />
                  ) : (
                    <ReactionsCount article={article} />
                  )}
                  <FavoritedMarker
                    favoritedByUserId={article.favorited_by_user_id}
                    currentUserId={currentUserId}
                  />
                  <CommentsCount
                    count={isStatus ? localCommentsCount : article.comments_count}
                    articlePath={article.url}
                    articleTitle={
                      isStatus
                        ? article.title_for_metadata || article.title
                        : article.title
                    }
                    onToggleInlineComment={
                      isStatus
                        ? () => setIsCommentOpen((prev) => !prev)
                        : undefined
                    }
                    isInlineCommentOpen={isStatus ? isCommentOpen : undefined}
                  />
                </div>
              )}

              <div className="crayons-story__save">
                <ReadingTime
                  readingTime={article.reading_time}
                  typeOf={article.type_of}
                />
                {isRoot && (
                  <small class="crayons-story__tertiary mr-2 fs-xs fw-bold">
                    {domain}
                  </small>
                )}
                <SaveButton
                  article={article}
                  isBookmarked={isBookmarked}
                  onClick={bookmarkClick}
                  saveable={saveable}
                />
                {isArticle && (
                  <div className="only-sidebar-menu-item trusted-visible-block align-center print-hidden">
                    <button
                      type="button"
                      className="crayons-btn crayons-btn--ghost crayons-btn--icon-rounded mod-actions-menu-btn"
                      data-article-path={article.path}
                      aria-label="Moderation"
                    >
                      <svg width="24" height="24" className="crayons-icon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                        <path d="M3.783 2.826L12 1l8.217 1.826a1 1 0 01.783.976v9.987a6 6 0 01-2.672 4.992L12 23l-6.328-4.219A6 6 0 013 13.79V3.802a1 1 0 01.783-.976zM5 4.604v9.185a4 4 0 001.781 3.328L12 20.597l5.219-3.48A4 4 0 0019 13.79V4.604L12 3.05 5 4.604zM13 10h3l-5 7v-5H8l5-7v5z" />
                      </svg>
                    </button>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {isStatus ? (
          <QuickieCommentSection
            article={article}
            comments={localComments}
            totalCount={localCommentsCount}
            maxVisibleComments={Math.max(2, addedCommentsCount + 2)}
            isOpen={isCommentOpen}
            onClose={() => setIsCommentOpen(false)}
            onCommentCreated={handleCommentCreated}
            currentUserId={currentUserId}
          />
        ) : (
          article.top_comments &&
          article.top_comments.length > 0 && (
            <CommentsList
              comments={article.top_comments}
              articlePath={article.url}
              totalCount={article.comments_count}
            />
          )
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
  saveable: false,
};

Article.propTypes = {
  article: articlePropTypes.isRequired,
  currentUserId: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  isBookmarked: PropTypes.bool,
  isFeatured: PropTypes.bool,
  isRoot: PropTypes.bool,
  feedStyle: PropTypes.string,
  bookmarkClick: PropTypes.func.isRequired,
  pinned: PropTypes.bool,
  saveable: PropTypes.bool.isRequired,
};
