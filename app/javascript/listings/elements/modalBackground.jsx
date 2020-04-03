import { h } from 'preact';
import PropTypes from 'prop-types';

const ModalBackground = ({ onClick }) => (
  <div
    className="classified-listings-modal-background"
    onClick={onClick}
    role="presentation"
    id="classified-listings-modal-background"
  />
);

ModalBackground.propTypes = {
  onClick: PropTypes.func.isRequired,
};

export default ModalBackground;
