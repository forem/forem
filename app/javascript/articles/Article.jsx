import { h } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../src/components/common-prop-types/article-prop-types';
import {
  CommentsCount,
  ContentTitle,
  OrganizationHeadline,
  PublishDate,
  ReadingTime,
  SaveButton,
  SearchSnippet,
  TagList,
  ReactionsCount,
} from './components';
import { PodcastArticle } from './PodcastArticle';

/* global timeAgo */

export const Article = ({
  article,
  currentTag,
  isBookmarked,
  reactionsIcon,
  commentsIcon,
  videoIcon,
  bookmarkClick,
}) => {
  if (article && article.type_of === 'podcast_episodes') {
    return <PodcastArticle article={article} />;
  }

  const timeAgoIndicator = timeAgo({
    oldTimeInSeconds: article.published_at_int,
    formatter: x => x,
  });

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
            <img src={videoIcon} alt="video camera" loading="lazy" />
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
            <SearchSnippet highlightText={article.highlight} />
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
              {timeAgoIndicator.length > 0 ? `(${timeAgoIndicator})` : ''}
            </span>
          ) : null}
        </a>
      </h4>

      <TagList tags={article.tag_list} />
      {article.class_name !== 'User' && (
        <CommentsCount
          count={article.comments_count}
          articlePath={article.path}
          icon={commentsIcon}
        />
      )}
      {article.class_name !== 'User' && (
        <ReactionsCount article={article} icon={reactionsIcon} />
      )}
      {article.class_name === 'Article' && (
        <ReadingTime
          articlePath={article.path}
          readingTime={article.reading_time}
        />
      )}
      <SaveButton
        article={article}
        isBookmarked={isBookmarked}
        onClick={bookmarkClick}
      />
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
  reactionsIcon: PropTypes.string.isRequired,
  commentsIcon: PropTypes.string.isRequired,
  videoIcon: PropTypes.string.isRequired,
  bookmarkClick: PropTypes.func.isRequired,
};
