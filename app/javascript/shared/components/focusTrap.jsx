import PropTypes from 'prop-types';
import { h, Fragment } from 'preact';
import { useLayoutEffect, useRef } from 'preact/hooks';
import { createFocusTrap } from 'focus-trap';
import { defaultChildrenPropTypes } from '../../common-prop-types';
import { KeyboardShortcuts } from './useKeyboardShortcuts';

/**
 * Wrapper component to create a focus trap within the HTML element found by the given selector
 *
 * @example
 * import { FocusTrap } from "shared/components/FocusTrap";
 *
 * const ExampleComponent = ({ onClose }) => (
 *   <FocusTrap selector=".component-with-focus-trap" onDeactivate={onClose}>
 *     <div class="component-with-focus-trap">
 *       <button onClick={onClose}>Close</button>
 *     </div>
 *   </FocusTrap>
 * )
 *
 * @param {string} selector The CSS selector for the element where focus is to be trapped
 * @param {Array} children Child element(s) passed via composition
 * @param {Function} onDeactivate Callback function to be called when the focus trap is deactivated by navigation or Escape press
 */
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
