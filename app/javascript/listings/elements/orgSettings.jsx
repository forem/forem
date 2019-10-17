// listings
import { h } from 'preact';
import PropTypes from 'prop-types';
import { OrganizationPicker } from '../../organization/OrgSettings';
import { organizationPropType } from '../../src/components/common-prop-types';

const OrgSettings = ({ organizations, organizationId, onToggle }) => (
  <div className="field">
    <label htmlFor="organizationId">Post under an organization:</label>
    <OrganizationPicker
      name="classified_listing[organization_id]"
      id="listing_organization_id"
      organizations={organizations}
      organizationId={organizationId}
      onBlur={onToggle}
    />
    <p>
      <em>Posting on behalf of org spends org credits.</em>
    </p>
  </div>
);

OrgSettings.propTypes = {
  onToggle: PropTypes.func.isRequired,
  organizationId: PropTypes.number.isRequired,
  organizations: PropTypes.arrayOf(organizationPropType).isRequired,
};

export default OrgSettings;
