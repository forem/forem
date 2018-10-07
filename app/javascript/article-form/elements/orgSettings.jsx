import { h } from 'preact';
import PropTypes from 'prop-types';

const OrgSettings = ({ organization, postUnderOrg, onToggle }) => (
  <div
    className='articleform__orgsettings'
    onClick={onToggle}
    >
    <img src={organization.profile_image_90} style={{opacity: postUnderOrg ? '1' : '0.7' }} /> {organization.name} <button class={postUnderOrg ? 'yes' : 'no'}>{postUnderOrg ? '✅ YES' : '◻️ NO'}</button>
  </div>
);

OrgSettings.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};

export default OrgSettings;
