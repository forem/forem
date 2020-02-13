import { h } from 'preact';
import PropTypes from 'prop-types';
import {
  articlePropTypes,
  articleSnippetResultPropTypes,
} from '../src/components/common-prop-types/article-prop-types';
import {
  organizationPropType,
  tagPropTypes,
} from '../src/components/common-prop-types';
import { PodcastArticle } from './PodcastArticle';

// TODO: faking this from backend function asset_path. Need to get this in the frontend.
const assetPath = relativeUrl => `/images/${relativeUrl}`;
const timeAgo = time => time;
const filterXSS = data => data;

// function timeAgo(oldTimeInSeconds, maxDisplayedAge = 60 * 60 * 24 - 1) {
//   const timeNow = new Date() / 1000;
//   const diff = Math.round(timeNow - oldTimeInSeconds);

//   if (diff > maxDisplayedAge) return '';

//   return `<span class='time-ago-indicator'>(${secondsToHumanUnitAgo(
//     diff,
//   )})</span>`;
// }

const TagList = ({ tags = [] }) => (
  <div className="tags">
    {tags.forEach(tag => (
      <a href={`/t/${tag}`}>
        <span className="tag">
          #$
          {tag}
        </span>
      </a>
    ))}
  </div>
);

TagList.propTypes = {
  tags: tagPropTypes.isRequired,
};

TagList.displayName = 'TagList';

const ContentTitle = ({ article, currentTag }) => (
  <h3>
    {article.flare_tag && currentTag !== article.flare_tag.name && (
      <span
        className="tag-identifier"
        style={{
          background: article.flare_tag.bg_color_hex,
          color: article.flare_tag.text_color_hex,
        }}
      >
        {`#${article.flare_tag.name}`}
      </span>
    )}
    {article.class_name === 'PodcastEpisode' && (
      <span className="tag-identifier">podcast</span>
    )}
    {article.class_name === 'User' && (
      <span
        className="tag-identifier"
        style={{ background: '#5874d9', color: 'white' }}
      >
        person
      </span>
    )}
    {filterXSS(article.title)}
  </h3>
);

ContentTitle.defaultProps = {
  currentTag: null,
};

ContentTitle.propTypes = {
  article: articlePropTypes.isRequired,
  currentTag: PropTypes.string,
};

ContentTitle.displayName = 'ContentTitle';

const SaveButton = ({ article }) => {
  if (article.class_name === 'Article') {
    return (
      <button
        type="button"
        className="article-engagement-count engage-button bookmark-button"
        data-reactable-id={article.id}
      >
        <span className="bm-initial">SAVE</span>
        <span className="bm-success">SAVED</span>
      </button>
    );
  }
  if (article.class_name === 'User') {
    return (
      <button
        type="button"
        style={{ width: '122px' }}
        className="article-engagement-count engage-button follow-action-button"
        data-info={`{"id":${article.id},"className":"User"}`}
        data-follow-action-button
      >
        &nbsp;
      </button>
    );
  }

  return null;
};

SaveButton.propTypes = {
  article: articlePropTypes.isRequired,
};

SaveButton.displayName = 'SaveButton';

const SearchSnippet = ({ snippetResult }) => {
  if (snippetResult && snippetResult.body_text) {
    let bodyTextSnippet = '';

    if (snippetResult.body_text.matchLevel !== 'none') {
      const firstSnippetChar = snippetResult.body_text.value[0];

      let startingEllipsis = '';
      if (firstSnippetChar.toLowerCase() !== firstSnippetChar.toUpperCase()) {
        startingEllipsis = '…';
      }

      bodyTextSnippet = `${startingEllipsis + snippetResult.body_text.value}…`;
    }

    let commentsBlobSnippet = '';

    if (
      snippetResult.comments_blob.matchLevel !== 'none' &&
      bodyTextSnippet === ''
    ) {
      const firstSnippetChar = snippetResult.comments_blob.value[0];
      let startingEllipsis = '';

      if (firstSnippetChar.toLowerCase() !== firstSnippetChar.toUpperCase()) {
        startingEllipsis = '…';
      }

      commentsBlobSnippet = `${startingEllipsis +
        snippetResult.comments_blob.value}… <i>(comments)</i>`;
    }

    if (bodyTextSnippet.length > 0 || commentsBlobSnippet.length > 0) {
      return (
        <div className="search-snippet">
          <span>
            {bodyTextSnippet}
            {commentsBlobSnippet}
          </span>
        </div>
      );
    }
  }

  return null;
};

SearchSnippet.propTypes = {
  // eslint-disable-next-line no-underscore-dangle
  snippetResult: articleSnippetResultPropTypes.isRequired,
};

SearchSnippet.displayName = 'SearchSnippet';

const ReactionsCount = ({ article }) => {
  const totalReactions = article.positive_reactions_count || 0;

  if (totalReactions > 0) {
    return (
      <div className="article-engagement-count reactions-count">
        <a href={article.path}>
          <img src={assetPath('reactions-stack.png')} alt="heart" />
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

const OrganizationHeadline = ({ organization }) => {
  if (organization && !document.getElementById('organization-article-index')) {
    return (
      <div className="article-organization-headline">
        <a className="org-headline-filler" href={`/${organization.slug}`}>
          <span className="article-organization-headline-inner">
            <img
              alt={`${organization.name} logo`}
              src={organization.profile_image_90}
              loading="lazy"
            />
            {organization.name}
          </span>
        </a>
      </div>
    );
  }

  return null;
};

OrganizationHeadline.defaultProps = {
  organization: null,
};

OrganizationHeadline.propTypes = {
  organization: organizationPropType,
};

OrganizationHeadline.displayName = 'OrganizationHeadline';

const ReadingTime = ({ articlePath, readingTime }) => {
  // we have ` ... || null` for the case article.reading_time is undefined
  return (
    <a href={articlePath} className="article-reading-time">
      {`${readingTime < 1 ? 1 : readingTime} min read`}
    </a>
  );
};

ReadingTime.defaultProps = {
  readingTime: null,
};

ReadingTime.propTypes = {
  articlePath: PropTypes.string.isRequired,
  readingTime: PropTypes.number,
};

ReadingTime.displayName = 'ReadingTime';

const CommentsCount = ({ count, articlePath }) => {
  if (count > 0) {
    return (
      <div className="article-engagement-count comments-count">
        <a href={`${articlePath}#comments`}>
          <img src={assetPath('comments-bubble.png')} alt="chat" />
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

const PublishDate = ({ readablePublishDate, publishedTimestamp }) => {
  if (publishedTimestamp) {
    return <time dateTime={publishedTimestamp}>{readablePublishDate}</time>;
  }

  return <time>{readablePublishDate}</time>;
};

PublishDate.defaultProps = {
  publishedTimestamp: null,
};

PublishDate.propTypes = {
  readablePublishDate: PropTypes.string.isRequired,
  publishedTimestamp: PropTypes.string,
};

PublishDate.displayName = 'PublishDate';

export const Article = ({ article, currentTag }) => {
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
            <img src={assetPath('video-camera.svg')} alt="video camera" />
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
          {filterXSS(article.user.name)}
          {article.readable_publish_date ? '・' : ''}
          {article.readable_publish_date && (
            <PublishDate
              readablePublishDate={article.readable_publish_date}
              publishedTimestamp={article.published_timestamp}
            />
          )}
          {article.published_at_int ? timeAgo(article.published_at_int) : ''}
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
      <SaveButton article={article} />
    </div>
  );
};

Article.defaultProps = {
  currentTag: null,
};

Article.propTypes = {
  article: articlePropTypes.isRequired,
  currentTag: PropTypes.string,
};
