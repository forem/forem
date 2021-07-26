import { h } from 'preact';
import {
  articlePropTypes,
  organizationPropType,
} from '../../common-prop-types';
import { PublishDate } from './PublishDate';

export const Meta = ({ article, organization }) => {
  const orgArticleIndexClassAbsent = !document.getElementById(
    'organization-article-index',
  );
  // TODO: Extract preview card
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
          <div class="profile-preview-card relative mb-4 s:mb-0 fw-medium hidden m:block">
            <button
              id={`story-author-preview-trigger-${article.id}`}
              aria-controls={`story-author-preview-content-${article.id}`}
              class="profile-preview-card__trigger px-0 crayons-btn crayons-btn--ghost p-0"
              aria-label={`${article.user.username} profile details`}
            >
              {article.user.name}
            </button>

            <div
              id={`story-author-preview-content-${article.id}`}
              class="profile-preview-card__content crayons-dropdown"
              style="border-top: var(--su-7) solid var(--card-color);"
              data-testid="profile-preview-card"
            >
              <div class="gap-4 grid">
                <div class="-mt-4">
                  <a href={`/${article.user.username}`} class="flex">
                    <span class="crayons-avatar crayons-avatar--xl mr-2 shrink-0">
                      <img
                        src={`${article.user.profile_image_90}`}
                        class="crayons-avatar__image"
                        alt=""
                        loading="lazy"
                      />
                    </span>
                    <span class="crayons-link crayons-subtitle-2 mt-5">
                      {article.user.name}
                    </span>
                  </a>
                </div>
                <div class="print-hidden">
                  <button
                    class="crayons-btn follow-action-button whitespace-nowrap follow-user w-100"
                    data-info={{
                      id: article.user_id,
                      className: 'User',
                      style: 'full',
                    }}
                  >
                    Follow
                  </button>
                </div>
                <span
                  class="author-preview-metadata-container"
                  data-author-id={article.user_id}
                />
              </div>
            </div>
          </div>
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
