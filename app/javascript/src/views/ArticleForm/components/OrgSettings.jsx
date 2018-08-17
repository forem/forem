import { h } from 'preact';
import PropTypes from 'prop-types';

const OrgSettings = ({ organization, postUnderOrg, onToggle }) => (
  <div
    className='articleform__orgsettings'
    style={{backgroundColor: organization.bg_color_hex, color: organization.text_color_hex}}
    onClick={onToggle}
    >
    Post From {organization.name} <button>{postUnderOrg ? 'YES' : 'NO'}</button>
  </div>
);

OrgSettings.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};

export default OrgSettings;
