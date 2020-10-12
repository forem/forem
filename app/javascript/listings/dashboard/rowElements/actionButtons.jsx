import PropTypes from 'prop-types';
import { h } from 'preact';
import { Button } from '@crayons';

const ActionButtons = ({ isDraft, editUrl, deleteConfirmUrl }) => {
  return (
    <div className="listing-row-actions">
      {isDraft && (
        <Button href={editUrl} className="dashboard-listing-edit-button">
          View draft
        </Button>
      )}
      <Button href={editUrl} className="dashboard-listing-edit-button">
        Edit
      </Button>
      <Button
        variant="danger"
        href={deleteConfirmUrl}
        className="dashboard-listing-delete-button"
      >
        Delete
      </Button>
    </div>
  );
};

ActionButtons.propTypes = {
  isDraft: PropTypes.bool.isRequired,
  editUrl: PropTypes.string.isRequired,
  deleteConfirmUrl: PropTypes.string.isRequired,
};

export default ActionButtons;
