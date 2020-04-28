import { h } from 'preact';
import PropTypes from 'prop-types';
import { OrganizationPicker } from '../../organization/OrganizationPicker';

export const PageTitle = ({organizations, organizationId, onToggle}) => {
  return (
    <div className="crayons-field__label">
      <span className="hidden s:inline-block">Write a new post</span>
      {organizations && organizations.length > 0 && (
        <span>
          <span className="hidden s:inline-block">&nbsp;under:</span>
          <span className="s:hidden">&nbsp;Organization:</span>
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
