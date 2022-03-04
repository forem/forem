import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../common-prop-types';
import { FocusTrap } from '../../shared/components/focusTrap';

/**
 * A component that creates a full-width modal that slides in from the bottom of viewport.
 *
 *
 * @param {object} props
 * @param {Array} props.children
 * @param {string} props.title The title to be applied to the dialog, surfaced to screen reader users
 * @param {Function} props.onClose Action to complete when user opts to close the drawer
 *
 * @example
 * const [isDrawerOpen, setIsDrawerOpen] = useState(false);
 * return (
 *   <div>
 *     <Button onClick={() => setIsDrawerOpen(true)}>Open drawer</Button>
 *     {isDrawerOpen && (
 *       <MobileDrawer
 *         title="Example MobileDrawer"
 *         onClose={() => setIsDrawerOpen(false)}
 *       >
 *         <h2>Lorem ipsum</h2>
 *         <Button onClick={() => setIsDrawerOpen(false)}>OK</Button>
 *       </MobileDrawer>
 *     )}
 *   </div>
 * );
 */
export const MobileDrawer = ({ children, title, onClose = () => {} }) => {
  return (
    <div className="crayons-mobile-drawer">
      <div className="crayons-mobile-drawer__overlay" />
      <FocusTrap
        clickOutsideDeactivates
        selector=".crayons-mobile-drawer__content"
        onDeactivate={onClose}
      >
        <div
          className="crayons-mobile-drawer__content"
          role="dialog"
          aria-modal="true"
          aria-label={title}
        >
          {children}
        </div>
      </FocusTrap>
    </div>
  );
};

MobileDrawer.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  title: PropTypes.string.isRequired,
  onClose: PropTypes.func,
};
