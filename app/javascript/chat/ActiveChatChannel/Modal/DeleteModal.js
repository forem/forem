import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button, Modal } from '@crayons';

/**
 * This is Delete message component modal.
 *
 * @param {object} props
 * @param {boolean} props.showDeleteModal
 * @param {function} props.handleMessageDelete
 * @param {function} props.handleCloseDeleteModal
 *
 * @component
 *
 * @example
 *
 * <DeleteModal
 *   showDeleteModal={showDeleteModal}
 *   handleMessageDelete={handleMessageDelete}
 *   handleCloseDeleteModal={handleCloseDeleteModal}
 * />
 */

function DeleteModal({
  showDeleteModal,
  handleMessageDelete,
  handleCloseDeleteModal,
}) {
  return showDeleteModal ? (
    <Modal title={''} size={'s'}>
      <h3>Are you sure, you want to delete this message?</h3>
      <div className="delete-actions__container">
        <Button
          className="crayons-btn crayons-btn--danger message__delete__button"
          onClick={handleMessageDelete}
          tabIndex="0"
          onKeyUp={(e) => {
            if (e.keyCode === 13) handleMessageDelete();
          }}
        >
          {' '}
          Delete
        </Button>
        <Button
          className="crayons-btn crayons-btn--secondary message__cancel__button"
          onClick={handleCloseDeleteModal}
          tabIndex="0"
          onKeyUp={(e) => {
            if (e.keyCode === 13) handleCloseDeleteModal();
          }}
        >
          {' '}
          Cancel
        </Button>
      </div>
    </Modal>
  ) : null;
}

DeleteModal.propTypes = {
  showDeleteModal: PropTypes.bool,
  handleCloseDeleteModal: PropTypes.func,
  handleMessageDelete: PropTypes.func,
};

export default DeleteModal;
