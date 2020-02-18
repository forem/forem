import { h } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../src/components/common-prop-types/article-prop-types';
import {
  ContentTitle,
  OrganizationHeadline,
  PublishDate,
  ReadingTime,
  SaveButton,
  SearchSnippet,
  TagList,
} from './components';
import { PodcastArticle } from './PodcastArticle';

/* global timeAgo */

// TODO: faking this from backend function asset_path. Need to get this in the frontend.
const assetPath = relativeUrl => `/images/${relativeUrl}`;

const ReactionsCount = ({ article }) => {
  const totalReactions = article.positive_reactions_count || 0;

  if (totalReactions > 0) {
    return (
      <div className="article-engagement-count reactions-count">
        <a href={article.path}>
          <img
            src={assetPath('reactions-stack.png')}
            alt="heart"
            loading="lazy"
          />
          <span
            id={`engagement-count-number-${article.id}`}
            className="engagement-count-number"
          >
            {totalReactions}
          </span>
        </a>
      </div>
    );
  }

  return null;
};

ReactionsCount.propTypes = {
  article: articlePropTypes.isRequired,
};

ReactionsCount.displayName = 'ReactionsCount';

const CommentsCount = ({ count, articlePath }) => {
  if (count > 0) {
    return (
      <div className="article-engagement-count comments-count">
        <a href={`${articlePath}#comments`}>
          <img
            src={assetPath('comments-bubble.png')}
            alt="chat"
            loading="lazy"
          />
          <span className="engagement-count-number">{count}</span>
        </a>
      </div>
    );
  }

  return null;
};

CommentsCount.defaultProps = {
  count: 0,
};

CommentsCount.propTypes = {
  count: PropTypes.number,
  articlePath: PropTypes.string.isRequired,
};

CommentsCount.displayName = 'CommentsCount';

export const Article = ({ article, currentTag, isBookmarked }) => {
  if (article && article.type_of === 'podcast_episodes') {
    return <PodcastArticle article={article} />;
  }

  return (
    <div
      className="single-article single-article-small-pic"
      data-content-user-id={article.user_id}
    >
      {article.cloudinary_video_url && (
        <a
          href={article.path}
          className="single-article-video-preview"
          style={`background-image:url(${article.cloudinary_video_url})`}
        >
          <div className="single-article-video-duration">
            <img
              src={assetPath('video-camera.svg')}
              alt="video camera"
              loading="lazy"
            />
            {article.video_duration_in_minutes}
          </div>
        </a>
      )}

      <OrganizationHeadline organization={article.organization} />
      <div className="small-pic">
        <a
          href={`/${article.user.username}`}
          className="small-pic-link-wrapper"
        >
          <img
            src={article.user.profile_image_90}
            alt={`${article.user.username} profile`}
            loading="lazy"
          />
        </a>
      </div>
      <a
        href={article.path}
        className="small-pic-link-wrapper index-article-link"
        id={`article-link-${article.id}`}
      >
        <div className="content">
          <ContentTitle article={article} currentTag={currentTag} />
          {article.class_name === 'Article' && (
            // eslint-disable-next-line no-underscore-dangle
            <SearchSnippet snippetResult={article._snippetResult} />
          )}
        </div>
      </a>
      <h4>
        <a href={`/${article.user.username}`}>
          {filterXSS(
            article.class_name === 'User'
              ? article.user.username
              : article.user.name,
          )}
          {article.readable_publish_date ? '・' : ''}
          {article.readable_publish_date && (
            <PublishDate
              readablePublishDate={article.readable_publish_date}
              publishedTimestamp={article.published_timestamp}
            />
          )}
          {article.published_at_int ? (
            <span className="time-ago-indicator">
              (
              {timeAgo({
                oldTimeInSeconds: article.published_at_int,
                formatter: x => x,
              })}
              )
            </span>
          ) : null}
        </a>
      </h4>

      <TagList tags={article.tag_list || article.cached_tag_list_array} />
      {article.class_name !== 'User' && (
        <CommentsCount
          count={article.comments_count}
          articlePath={article.path}
        />
      )}
      {article.class_name !== 'User' && <ReactionsCount article={article} />}
      {article.class_name === 'Article' && (
        <ReadingTime
          articlePath={article.path}
          readingTime={article.reading_time}
        />
      )}
      <SaveButton article={article} isBookmarked={isBookmarked} />
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
};
