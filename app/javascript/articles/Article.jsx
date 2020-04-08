import { h } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../src/components/common-prop-types/article-prop-types';
import {
  CommentsCount,
  CommentsList,
  ContentTitle,
  Author,
  OverflowNavigation,
  SaveButton,
  SearchSnippet,
  TagList,
  ReactionsCount,
} from './components';
import { PodcastArticle } from './PodcastArticle';

export const Article = ({
  article,
  currentTag,
  isBookmarked,
  videoIcon,
  bookmarkClick,
}) => {
  if (article && article.type_of === 'podcast_episodes') {
    return <PodcastArticle article={article} />;
  }

  return (
    <div
      className="crayons-story"
      data-content-user-id={article.user_id}
    >
      {article.cloudinary_video_url && (
        <a
          href={article.path}
          className="crayons-story__cover"
        >
          <img src={article.cloudinary_video_url} alt="Video for TODO: ARTICLE TITLE" loading="lazy" />
          <div className="single-article-video-duration">
            <img src={videoIcon} alt="video camera" loading="lazy" />
            {article.video_duration_in_minutes}
          </div>
        </a>
      )}

      <div className="crayons-story__body">
        <div className="crayons-story__top">
          <Author article={article} organization={article.organization} />
          <OverflowNavigation />
        </div>

        <div className="crayons-story__indention">
          <ContentTitle article={article} currentTag={currentTag} />

          {article.class_name === 'Article' && (
            // eslint-disable-next-line no-underscore-dangle
            <SearchSnippet highlightText={article.highlight} />
          )}

          <TagList tags={article.tag_list} />

          <div className="crayons-story__bottom">
            <div className="crayons-story__details">
              {article.class_name !== 'User' && (
                <ReactionsCount article={article} />
              )}
              {article.class_name !== 'User' && (
                <CommentsCount
                  count={article.comments_count}
                  articlePath={article.path}
                />
              )}
            </div>

            <SaveButton
              article={article}
              isBookmarked={isBookmarked}
              onClick={bookmarkClick}
            />
          </div>
        </div>
      </div>

      <CommentsList />
    </div>
  );
};

Article.defaultProps = {
  currentTag: null,
  isBookmarked: false,
};

Article.propTypes = {
  article: articlePropTypes.isRequired,
  currentTag: PropTypes.string,
  isBookmarked: PropTypes.bool,
  videoIcon: PropTypes.string.isRequired,
  bookmarkClick: PropTypes.func.isRequired,
};
