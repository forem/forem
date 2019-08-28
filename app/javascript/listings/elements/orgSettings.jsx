// listings
import { h } from 'preact';
import PropTypes from 'prop-types';

const orgOptions = (organizations, organizationId) => {
  const orgs = organizations.map(organization => {
    if (organizationId === organization.id) {
      return (
        <option value={organization.id} selected>
          {organization.name}
        </option>
      );
    }
    return <option value={organization.id}>{organization.name}</option>;
  });
  const nullOrgOption =
    organizationId === null ? (
      <option value="" selected>
        None
      </option>
    ) : (
      <option value="">None</option>
    );
  orgs.unshift(nullOrgOption); // make first option as "None"
  return orgs;
};

const OrgSettings = ({ organizations, organizationId, onToggle }) => (
  <div className="field">
    <label htmlFor="organizationId">Post under an organization:</label>
    <select
      name="classified_listing[organization_id]"
      id="listing_organization_id"
      onBlur={onToggle}
    >
      {orgOptions(organizations, organizationId)}
    </select>
    <p>
      <em>Posting on behalf of org spends org credits.</em>
    </p>
  </div>
);

OrgSettings.propTypes = {
  onToggle: PropTypes.func.isRequired,
};

export default OrgSettings;
