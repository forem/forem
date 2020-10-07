import PropTypes from 'prop-types';
import { h } from 'preact';

const ActionButtons = ({ isDraft, editUrl, deleteConfirmUrl }) => {
  return (
    <div className="listing-row-actions">
      {isDraft && (
        <a
          href={editUrl}
          className="dashboard-listing-edit-button crayons-btn"
        >
          DRAFT
        </a>
      )}
      <a
        href={editUrl}
        className="dashboard-listing-edit-button crayons-btn"
      >
        EDIT
      </a>
      <a
        href={deleteConfirmUrl}
        className="dashboard-listing-delete-button crayons-btn"
        data-no-instant
      >
        DELETE
      </a>
    </div>
  );
};

ActionButtons.propTypes = {
  isDraft: PropTypes.bool.isRequired,
  editUrl: PropTypes.string.isRequired,
  deleteConfirmUrl: PropTypes.string.isRequired,
};

export default ActionButtons;
