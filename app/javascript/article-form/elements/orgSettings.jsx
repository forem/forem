import { h } from 'preact';
import PropTypes from 'prop-types';

const orgOptions = (organizations, organizationId) => {
  const orgs = organizations.map((organization) => {
    if(organizationId === organization.id) {
      return(
        <option value={organization.id} selected>{organization.name}</option>
      )
    }
    return (
      <option value={organization.id}>{organization.name}</option>
    )
  })
  const nullOrgOption = organizationId === null ? <option value="" selected>None</option> : <option value="">None</option>
  orgs.unshift(nullOrgOption) // first element
  return orgs
}

const OrgSettings = ({ organizations, organizationId }) => (
  <div className="articleform__orgsettings">
    Publish under an organization:
    <select name="article[publish_under_org]" id="article_publish_under_org">
      {orgOptions(organizations, organizationId)}
    </select>
  </div>
);

OrgSettings.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};

export default OrgSettings;
