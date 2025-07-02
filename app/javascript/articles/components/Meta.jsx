import { h } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../../common-prop-types';
import { MinimalProfilePreviewCard } from '../../profilePreviewCards/MinimalProfilePreviewCard';
import { PublishDate } from './PublishDate';

/* global timeAgo */

export const Meta = ({ article, organization }) => {
  const orgArticleIndexClassAbsent = !document.getElementById(
    'organization-article-index',
  );

  if (article.title === '[Boost]') {
    return '';
  }

  return (
    <div className="crayons-story__meta">
      <div className="crayons-story__author-pic">
        {organization && orgArticleIndexClassAbsent && (
          <a
            href={`/${organization.slug}`}
            className="crayons-logo crayons-logo--l"
          >
            <img
              alt={`${organization.name} logo`}
              src={organization.profile_image_90}
              className="crayons-logo__image"
              loading="lazy"
            />
          </a>
        )}
        <a
          href={`/${article.user.username}`}
          className={`crayons-avatar ${
            organization && orgArticleIndexClassAbsent
              ? 'crayons-avatar--s absolute -right-2 -bottom-2 border-solid border-2 border-base-inverted'
              : 'crayons-avatar--l'
          }`}
        >
          <img
            src={article.user.profile_image_90}
            alt={`${article.user.username} profile`}
            className="crayons-avatar__image"
            loading="lazy"
          />
        </a>
      </div>
      <div>
        <div>
          <a
            href={`/${article.user.username}`}
            className="crayons-story__secondary fw-medium m:hidden"
          >
            {filterXSS(
              article.class_name === 'User'
                ? article.user.username
                : article.user.name,
            )}
          </a>          
          <MinimalProfilePreviewCard
            triggerId={`story-author-preview-trigger-${article.id}`}
            contentId={`story-author-preview-content-${article.id}`}
            username={article.user.username}
            name={article.user.name}
            profileImage={article.user.profile_image_90}
            userId={article.user_id}
            subscriber={article.user.cached_base_subscriber ? 'true' : 'false'}
          />
          {organization &&
            !document.getElementById('organization-article-index') && (
              <span>
                <span className="crayons-story__tertiary fw-normal">
                  {' for '}
                </span>
                <a
                  href={`/${organization.slug}`}
                  className="crayons-story__secondary fw-medium"
                >
                  {organization.name}
                </a>
              </span>
            )}
          {article.type_of === 'status' && (<div class='color-base-60 pl-1 inline-block fs-xs'>{timeAgo({
              oldTimeInSeconds: article.published_at_int,
              formatter: (x) => x,
              maxDisplayedAge: 60 * 60 * 24 * 7,
            })}</div>)}
          {article.type_of === 'status' && article.edited_at > article.published_timestamp && (<div class='color-base-60 pl-1 inline-block fs-xs'>(Edited)</div>)}
        </div>
        {article.type_of !== 'status' && (<a href={article.url} className="crayons-story__tertiary fs-xs">
          <PublishDate
            readablePublishDate={article.readable_publish_date}
            publishedTimestamp={article.published_timestamp}
            publishedAtInt={article.published_at_int}
          />
        </a>)}
      </div>
    </div>
  );
};

Meta.defaultProps = {
  organization: null,
};

Meta.propTypes = {
  article: articlePropTypes.isRequired,
  organization: PropTypes.shape({
    name: PropTypes.string.isRequired,
    profile_image_90: PropTypes.string.isRequired,
    slug: PropTypes.string.isRequired,
  }),
};

Meta.displayName = 'Meta';
