import { h } from 'preact';
import { articlePropTypes } from '../../src/components/common-prop-types';
import { organizationPropType } from '../../src/components/common-prop-types';

export const Author = ({ article, organization }) => (
  <div className="crayons-story__meta">
    <div className="crayons-story__author-pic">
      {organization && !document.getElementById('organization-article-index') && (
        <a href={`/${organization.slug}`} className="crayons-logo crayons-logo--l">
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
          organization && !document.getElementById('organization-article-index') ? 'crayons-avatar--s absolute -right-2 -bottom-2 border-solid border-2 border-base-inverted' : 'crayons-avatar--l'
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
        <a href={`/${article.user.username}`} className="crayons-story__secondary fw-bold">
          {filterXSS(
            article.class_name === 'User'
              ? article.user.username
              : article.user.name,
          )}
        </a> 
        {organization && !document.getElementById('organization-article-index') && (
          <span>
            <span className="crayons-story__tertiary fw-normal">for</span> 
            <a href={`/${organization.slug}`} className="crayons-story__secondary fw-bold">{organization.name}</a>
          </span>
        )}
      </p>
      <a href={article.path} className="crayons-story__tertiary">
        Posted 7 hours ago
      </a>
    </div>
  </div>
);

Author.defaultProps = {
  organization: null,
};

Author.propTypes = {
  article: articlePropTypes.isRequired,
  organization: organizationPropType,
};

Author.displayName = 'Author';
