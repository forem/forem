import { h } from 'preact';
import PropTypes from 'prop-types';

export const ModalBackground = ({ onClick }) => (
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
