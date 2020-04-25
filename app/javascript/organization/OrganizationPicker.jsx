import { h } from 'preact';
import PropTypes from 'prop-types';
import { organizationPropType } from '../src/components/common-prop-types';

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

  return [nullOrgOption, ...orgs];
};

export const OrganizationPicker = ({
  name,
  id,
  className,
  organizations,
  organizationId,
  onToggle,
}) => (
  <select name={name} id={id} className={className} onBlur={onToggle}>
    {orgOptions(organizations, organizationId)}
  </select>
);

OrganizationPicker.propTypes = {
  name: PropTypes.string.isRequired,
  id: PropTypes.string.isRequired,
  className: PropTypes.string.isRequired,
  onToggle: PropTypes.func.isRequired,
  organizationId: PropTypes.number.isRequired,
  organizations: PropTypes.arrayOf(organizationPropType).isRequired,
};
