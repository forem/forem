import { h } from 'preact';
import PropTypes from 'prop-types';
import { Close } from './Close';
import { Tabs } from './Tabs';
import { PageTitle } from './PageTitle';

export const Header = ({onPreview, previewShowing, organizations, organizationId, onToggle, logoSvg}) => {
  return (
    <div className="crayons-article-form__header">
      <a href="/" className="crayons-article-form__logo" aria-label="Home" dangerouslySetInnerHTML={{__html: logoSvg}} />
      <PageTitle
        organizations={organizations}
        organizationId={organizationId}
        onToggle={onToggle}
      />
      <Tabs 
        onPreview={onPreview} 
        previewShowing={previewShowing} 
      />
      <Close />
    </div>
  );
};

Header.propTypes = {
  onPreview: PropTypes.func.isRequired,
  previewShowing: PropTypes.bool.isRequired,
  organizations: PropTypes.string.isRequired,
  organizationId: PropTypes.string.isRequired,
  onToggle: PropTypes.string.isRequired,
  logoSvg: PropTypes.string.isRequired,
};

Header.displayName = 'Header';
