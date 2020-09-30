import { h } from 'preact';
import PropTypes from 'prop-types';

const DeleteModal = ({
  showDeleteModal,
  handleMessageDelete,
  handleCloseDeleteModal,
}) => {
  return (
    <div
      id="message"
      className={
        showDeleteModal
          ? 'message__delete__modal crayons-modal crayons-modal--s absolute'
          : 'message__delete__modal message__delete__modal__hide crayons-modal crayons-modal--s absolute'
      }
      aria-hidden={showDeleteModal}
      role="dialog"
    >
      <div className="crayons-modal__box">
        <div className="crayons-modal__box__body">
          <h3>Are you sure, you want to delete this message?</h3>
          <div className="delete-actions__container">
            <div
              role="button"
              className="crayons-btn crayons-btn--danger message__delete__button"
              onClick={handleMessageDelete}
              tabIndex="0"
              onKeyUp={(e) => {
                if (e.keyCode === 13) handleMessageDelete();
              }}
            >
              {' '}
              Delete
            </div>
            <div
              role="button"
              className="crayons-btn crayons-btn--secondary message__cancel__button"
              onClick={handleCloseDeleteModal}
              tabIndex="0"
              onKeyUp={(e) => {
                if (e.keyCode === 13) handleCloseDeleteModal();
              }}
            >
              {' '}
              Cancel
            </div>
          </div>
        </div>
      </div>
      <div className="crayons-modal__overlay" />
    </div>
  );
};

DeleteModal.propTypes = {
  showDeleteModal: PropTypes.bool,
  handleCloseDeleteModal: PropTypes.func,
  handleMessageDelete: PropTypes.func,
};

export default DeleteModal;
