import PropTypes from 'prop-types';
import { h } from 'preact';
import { Link } from '@crayons';

export const ActionButtons = ({ isDraft, editUrl, deleteConfirmUrl }) => {
  return (
    <div className="listing-row-actions flex">
      {isDraft && (
        <Link block href={editUrl}>
          View draft
        </Link>
      )}
      <Link block href={editUrl}>
        Edit
      </Link>
      <Link block href={deleteConfirmUrl}>
        Delete
      </Link>
    </div>
  );
};

ActionButtons.propTypes = {
  isDraft: PropTypes.bool.isRequired,
  editUrl: PropTypes.string.isRequired,
  deleteConfirmUrl: PropTypes.string.isRequired,
};
