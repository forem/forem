import PropTypes from 'prop-types';
import { h, Fragment } from 'preact';
import { useLayoutEffect, useRef } from 'preact/hooks';
import { createFocusTrap } from 'focus-trap';
import { defaultChildrenPropTypes } from '../../common-prop-types';
import { KeyboardShortcuts } from './useKeyboardShortcuts';

export const FocusTrap = ({ selector, children, onDeactivate }) => {
  const focusTrap = useRef(null);

  const currentLocationHref = document.location.href;

  const routeChangeObserver = new MutationObserver((mutations) => {
    const hasRouteChanged = mutations.some(
      () => currentLocationHref !== document.location.href,
    );

    // Ensure trap deactivates if user navigates from the page
    if (hasRouteChanged) {
      focusTrap.current?.deactivate();
      routeChangeObserver.disconnect();
    }
  });

  useLayoutEffect(() => {
    focusTrap.current = createFocusTrap(selector, {
      escapeDeactivates: false,
    });

    focusTrap.current.activate();
    routeChangeObserver.observe(document.querySelector('body'), {
      childList: true,
    });

    return () => {
      focusTrap.current.deactivate();
      routeChangeObserver.disconnect();
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
