import { h } from 'preact';
import {
  articlePropTypes,
  organizationPropType,
} from '../../common-prop-types';
import { MinimalProfilePreviewCard } from '../../profilePreviewCards/MinimalProfilePreviewCard';
import { PublishDate } from './PublishDate';

export const Meta = ({ article, organization }) => {
  const orgArticleIndexClassAbsent = !document.getElementById(
    'organization-article-index',
  );

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
        <p>
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
        </p>
        <a href={article.path} className="crayons-story__tertiary fs-xs">
          <PublishDate
            readablePublishDate={article.readable_publish_date}
            publishedTimestap={article.published_timestamp}
            publishedAtInt={article.published_at_int}
          />
        </a>
      </div>
    </div>
  );
};

Meta.defaultProps = {
  organization: null,
};

Meta.propTypes = {
  article: articlePropTypes.isRequired,
  organization: organizationPropType,
};

Meta.displayName = 'Meta';
