import PropTypes from 'prop-types';
import { h } from 'preact';
import { i18next } from '@utilities/locale';
import { Button } from '@crayons';

export const ActionButtons = ({ isDraft, editUrl, deleteConfirmUrl }) => {
  return (
    <div className="listing-row-actions crayons-btn-actions">
      {isDraft && (
        <Button tagName="a" url={editUrl}>
          {i18next.t('listings.actions.delete')}
        </Button>
      )}
      <Button tagName="a" url={editUrl}>
        {i18next.t('listings.actions.edit')}
      </Button>
      <Button variant="danger" tagName="a" url={deleteConfirmUrl}>
        {i18next.t('listings.actions.delete')}
      </Button>
    </div>
  );
};

ActionButtons.propTypes = {
  isDraft: PropTypes.bool.isRequired,
  editUrl: PropTypes.string.isRequired,
  deleteConfirmUrl: PropTypes.string.isRequired,
};
