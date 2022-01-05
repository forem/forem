import { h } from 'preact';
import PropTypes from 'prop-types';
import { OrganizationPicker } from '../../organization/OrganizationPicker';
import { locale } from '../../utilities/locale';

export const PageTitle = ({ organizations, organizationId, onToggle }) => {
  return (
    <div className="crayons-field__label flex items-center flex-1">
      <span className="hidden s:inline-block mr-2 whitespace-nowrap">
        {locale('views.editor.create')}
      </span>
      {organizations && organizations.length > 0 && (
        <div>
          <OrganizationPicker
            name="article[organization_id]"
            id="article_publish_under_org"
            className="crayons-select mt-0"
            organizations={organizations}
            organizationId={organizationId}
            onToggle={onToggle}
            emptyLabel="Personal"
          />
        </div>
      )}
    </div>
  );
};

PageTitle.propTypes = {
  organizations: PropTypes.arrayOf(PropTypes.string).isRequired,
  organizationId: PropTypes.string,
  onToggle: PropTypes.func.isRequired,
};

PageTitle.displayName = 'Organization';
