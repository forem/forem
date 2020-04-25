import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types/default-children-prop-types';

export const Modal = ({children}) => {
  return (
    <div className="crayons-modal">
      <div className="crayons-modal__box">
        {children}
      </div>
      <div 
        className="crayons-modal__overlay" 
      />
    </div>
  );
};

Modal.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
};

Modal.displayName = 'Modal';
