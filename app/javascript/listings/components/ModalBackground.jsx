import { h } from 'preact';
import PropTypes from 'prop-types';

const ModalBackground = ({ onClick }) => (
  <div
    data-testid="listings-modal-background"
    className="crayons-modal__overlay"
    onClick={onClick}
    role="presentation"
    id="listings-modal-background"
  />
);

ModalBackground.propTypes = {
  onClick: PropTypes.func.isRequired,
};

export default ModalBackground;
