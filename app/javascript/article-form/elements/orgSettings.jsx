import { h } from 'preact';
import PropTypes from 'prop-types';

const OrgSettings = ({ organizations, postUnderOrg}) => (
  <div className="articleform__orgsettings">
    Publish Under Organization:
    <select name="article[publish_under_org]" id="article_publish_under_org" style="vertical-align:middle;">
      
    </select>
  </div>
);

OrgSettings.propTypes = {
  onChange: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};

export default OrgSettings;
