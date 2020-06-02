import { h } from 'preact';
import PropTypes from 'prop-types';

const ModalBackground = ({ onClick }) => (
  <div
    className="listings-modal-background"
    onClick={onClick}
    role="presentation"
    id="listings-modal-background"
  />
);

ModalBackground.propTypes = {
  onClick: PropTypes.func.isRequired,
};

export default ModalBackground;
