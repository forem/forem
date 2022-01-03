import { h } from 'preact';
import PropTypes from 'prop-types';
import { Close } from './Close';
import { Tabs } from './Tabs';
import { PageTitle } from './PageTitle';

export const Header = ({
  onPreview,
  previewShowing,
  organizations,
  organizationId,
  onToggle,
  siteLogo,
  displayModal,
}) => {
  return (
    <div className="crayons-article-form__header">
      <span
        className="crayons-article-form__logo"
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{ __html: siteLogo }}
      />
      <PageTitle
        organizations={organizations}
        organizationId={organizationId}
        onToggle={onToggle}
      />
      <Tabs onPreview={onPreview} previewShowing={previewShowing} />
      <Close displayModal={displayModal} />
    </div>
  );
};

Header.propTypes = {
  displayModal: PropTypes.func.isRequired,
  onPreview: PropTypes.func.isRequired,
  previewShowing: PropTypes.bool.isRequired,
  organizations: PropTypes.arrayOf(PropTypes.object).isRequired,
  organizationId: PropTypes.string,
  onToggle: PropTypes.func.isRequired,
  siteLogo: PropTypes.string.isRequired,
};

Header.displayName = 'Header';
