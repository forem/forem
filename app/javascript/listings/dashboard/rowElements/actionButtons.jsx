import PropTypes from 'prop-types';
import { h } from 'preact';
import { Button } from '@crayons';

const ActionButtons = ({ isDraft, editUrl, deleteConfirmUrl }) => {
  return (
    <div className="listing-row-actions">
      {isDraft && (
        <Button tagName="a" url={editUrl}>
          View draft
        </Button>
      )}
      <Button tagName="a" url={editUrl}>
        Edit
      </Button>
      <Button variant="danger" tagName="a" url={deleteConfirmUrl}>
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
