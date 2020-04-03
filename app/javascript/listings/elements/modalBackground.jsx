import { h } from 'preact';
import PropTypes from 'prop-types';

const ModalBackground = ({ shouldRender, onClick }) =>
  shouldRender && (
    <div
      className="classified-listings-modal-background"
      onClick={onClick}
      role="presentation"
      id="classified-listings-modal-background"
    />
  );

ModalBackground.propTypes = {
  shouldRender: PropTypes.bool.isRequired,
  onClick: PropTypes.func.isRequired,
};

export default ModalBackground;
