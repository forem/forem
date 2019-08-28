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
  <div className="articleform__orgsettings">
    Publish under an organization:
    <select
      name="article[organization_id]"
      id="article_publish_under_org"
      onBlur={onToggle}
    >
      {orgOptions(organizations, organizationId)}
    </select>
  </div>
);

OrgSettings.propTypes = {
  onToggle: PropTypes.func.isRequired,
};

export default OrgSettings;
