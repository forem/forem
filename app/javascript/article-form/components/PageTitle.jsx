import { h } from 'preact';
import PropTypes from 'prop-types';
import { OrganizationPicker } from '../../organization/OrganizationPicker';

export const PageTitle = ({organizations, organizationId, onToggle}) => {
  return (
    <div className="crayons-field__label">
      Write a new post
      { organizations && organizations.length > 0 && (
        <span>
          &nbsp;under:
          <OrganizationPicker
            name="article[organization_id]"
            id="article_publish_under_org"
            className="crayons-select w-auto ml-2 mt-0"
            organizations={organizations}
            organizationId={organizationId}
            onToggle={onToggle}
          />
        </span>
      )}
    </div>
  );
};

PageTitle.propTypes = {
  organizations: PropTypes.string.isRequired,
  organizationId: PropTypes.string.isRequired,
  onToggle: PropTypes.string.isRequired,
};

PageTitle.displayName = 'Organization';
