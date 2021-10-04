import { h } from 'preact';
import PropTypes from 'prop-types';
import { organizationPropType } from '../common-prop-types';
import { i18next } from '@utilities/locale';

const orgOptions = (organizations, organizationId, emptyLabel) => {
  const orgs = organizations.map((organization) => {
    if (organizationId === organization.id) {
      return (
        <option value={organization.id} selected>
          {organization.name}
        </option>
      );
    }
    return (
      <option key={organization.id} value={organization.id}>
        {organization.name}
      </option>
    );
  });
  const nullOrgOption =
    organizationId === null ? (
      <option value="" selected>
        {emptyLabel}
      </option>
    ) : (
      <option value="">{emptyLabel}</option>
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
  emptyLabel,
}) => (
  <select
    aria-label={i18next.t('org.aria_label')}
    name={name}
    id={id}
    className={className}
    onBlur={onToggle}
  >
    {orgOptions(organizations, organizationId, emptyLabel)}
  </select>
);

OrganizationPicker.defaultProps = {
  emptyLabel: i18next.t('org.empty'),
};

OrganizationPicker.propTypes = {
  name: PropTypes.string.isRequired,
  id: PropTypes.string.isRequired,
  className: PropTypes.string.isRequired,
  emptyLabel: PropTypes.string,
  onToggle: PropTypes.func.isRequired,
  organizationId: PropTypes.number.isRequired,
  organizations: PropTypes.arrayOf(organizationPropType).isRequired,
};
