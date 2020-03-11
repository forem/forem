import { h } from 'preact';
import { organizationPropType } from '../../src/components/common-prop-types';

export const OrganizationHeadline = ({ organization }) => {
  if (organization && !document.getElementById('organization-article-index')) {
    return (
      <div className="article-organization-headline">
        <a className="org-headline-filler" href={`/${organization.slug}`}>
          <img
            alt={`${organization.name} logo`}
            src={organization.profile_image_90}
            loading="lazy"
          />
          {organization.name}
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
