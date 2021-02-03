import PropTypes from 'prop-types';
import { h, Fragment } from 'preact';
import { useLayoutEffect, useRef } from 'preact/hooks';
import { createFocusTrap } from 'focus-trap';
import { defaultChildrenPropTypes } from '../../common-prop-types';
import { KeyboardShortcuts } from './useKeyboardShortcuts';

export const FocusTrap = ({ selector, children, onDeactivate }) => {
  const focusTrap = useRef(null);

  useLayoutEffect(() => {
    focusTrap.current = createFocusTrap(selector, {
      escapeDeactivates: false,
    });

    focusTrap.current.activate();
    return () => {
      focusTrap.current.deactivate();
    };
  });

  const shortcuts = {
    escape: onDeactivate,
  };

  return (
    <Fragment>
      {children}
      <KeyboardShortcuts shortcuts={shortcuts} />
    </Fragment>
  );
};

FocusTrap.defaultProps = {
  selector: '.crayons-modal',
  onDeactivate: () => {},
};

FocusTrap.propTypes = {
  selector: PropTypes.string,
  children: defaultChildrenPropTypes.isRequired,
  onDeactivate: PropTypes.func,
};
