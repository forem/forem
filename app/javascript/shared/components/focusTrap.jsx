import PropTypes from 'prop-types';
import { useLayoutEffect, useRef } from 'preact/hooks';
import { createFocusTrap } from 'focus-trap';
import { defaultChildrenPropTypes } from '../../common-prop-types';

const FocusTrap = ({ selector, children }) => {
  const focusTrap = useRef(null);

  useLayoutEffect(() => {
    focusTrap.current = createFocusTrap(selector);
    focusTrap.current.activate();
    return () => {
      focusTrap.current.deactivate();
    };
  });

  return children;
};

FocusTrap.defaultProps = {
  selector: '.crayons-modal',
};

FocusTrap.propTypes = {
  selector: PropTypes.string,
  children: defaultChildrenPropTypes.isRequired,
};

export default FocusTrap;
