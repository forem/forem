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
  feedStyle,
}) => {
  if (article && article.type_of === 'podcast_episodes') {
    return <PodcastArticle article={article} />;
  }

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
    !article.cloudinary_video_url;

  // pinned article can have a cover image
  showCover = showCover || (article.pinned && article.main_image);

  return (
    <article
      className={`crayons-story cursor-pointer${
        isFeatured ? ' crayons-story--featured' : ''
      }`}
      id={isFeatured ? 'featured-story-marker' : `article-${article.id}`}
      data-content-user-id={article.user_id}
    >
      <a
        href={article.path}
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
              window.open(article.path, '_blank');
            } else {
              const fullUrl = window.location.origin + article.path; // InstantClick deals with full urls
              InstantClick.preload(fullUrl);
              InstantClick.display(fullUrl);
            }
          }
        }}
      >
        {article.cloudinary_video_url && <Video article={article} />}

        {showCover && <ArticleCoverImage article={article} />}
        <div className="crayons-story__body">
          <div className="crayons-story__top">
            <Meta article={article} organization={article.organization} />
            {article.pinned && (
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
            <TagList tags={article.tag_list} flare_tag={article.flare_tag} />

            {article.class_name === 'Article' && (
              // eslint-disable-next-line no-underscore-dangle
              <SearchSnippet highlightText={article.highlight} />
            )}

            <div className="crayons-story__bottom">
              {article.class_name !== 'User' && (
                <div className="crayons-story__details">
                  <ReactionsCount article={article} />
                  <CommentsCount
                    count={article.comments_count}
                    articlePath={article.path}
                  />
                </div>
              )}

              <div className="crayons-story__save">
                <ReadingTime readingTime={article.reading_time} />

                <SaveButton
                  article={article}
                  isBookmarked={isBookmarked}
                  onClick={bookmarkClick}
                />
              </div>
            </div>
          </div>
        </div>

        {article.top_comments && article.top_comments.length > 0 && (
          <CommentsList
            comments={article.top_comments}
            articlePath={article.path}
            totalCount={article.comments_count}
          />
        )}
      </div>
    </article>
  );
};

Article.defaultProps = {
  isBookmarked: false,
  isFeatured: false,
  feedStyle: 'basic',
};

Article.propTypes = {
  article: articlePropTypes.isRequired,
  isBookmarked: PropTypes.bool,
  isFeatured: PropTypes.bool,
  feedStyle: PropTypes.string,
  bookmarkClick: PropTypes.func.isRequired,
};
