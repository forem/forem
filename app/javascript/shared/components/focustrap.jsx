import PropTypes from 'prop-types';
import { h, Fragment } from 'preact';
import { useEffect, useRef } from 'preact/hooks';
import { createFocusTrap } from 'focus-trap';
import { defaultChildrenPropTypes } from '../../common-prop-types';

const FocusTrap = ({ selector, children }) => {
  const focusTrap = useRef(null);

  useEffect(() => {
    focusTrap.current = createFocusTrap(selector);
    focusTrap.current.activate();
    return () => {
      focusTrap.current.deactivate();
    };
  });

  return <Fragment>{children}</Fragment>;
};

FocusTrap.defaultProps = {
  selector: '.crayons-modal',
};

FocusTrap.propTypes = {
  selector: PropTypes.string,
  children: defaultChildrenPropTypes.isRequired,
};

export default FocusTrap;
