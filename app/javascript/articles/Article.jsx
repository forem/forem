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

  const showCover =
    (isFeatured || (feedStyle === 'rich' && article.main_image)) &&
    !article.cloudinary_video_url;

  return (
    <article
      className={`crayons-story cursor-pointer${
        isFeatured ? ' crayons-story--featured' : ''
      }`}
      id={isFeatured ? 'featured-story-marker' : `article-${article.id}`}
      data-content-user-id={article.user_id}
      data-testid={isFeatured ? 'featured-article' : `article-${article.id}`}
    >
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
          </div>

          <div className="crayons-story__indention">
            <ContentTitle article={article} />
            <TagList tags={article.tag_list} />

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
