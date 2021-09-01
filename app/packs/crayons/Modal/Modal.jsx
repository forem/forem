import { h } from 'preact';
import PropTypes from 'prop-types';
import { FocusTrap } from '../../shared/components/focusTrap';
import { defaultChildrenPropTypes } from '../../common-prop-types';
import { Button } from '@crayons';

function getAdditionalClassNames({ size, className }) {
  let additionalClassNames = '';

  if (size && size.length > 0 && size !== 'default') {
    additionalClassNames += ` crayons-modal--${size}`;
  }

  if (className && className.length > 0) {
    additionalClassNames += ` ${className}`;
  }

  return additionalClassNames;
}

const CloseIcon = () => (
  <svg
    width="24"
    height="24"
    viewBox="0 0 24 24"
    className="crayons-icon"
    xmlns="http://www.w3.org/2000/svg"
    role="img"
    aria-labelledby="714d29e78a3867c79b07f310e075e824"
  >
    <title id="714d29e78a3867c79b07f310e075e824">Close</title>
    <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" />
  </svg>
);

/**
 * A modal component which can be presented with or without an overlay.
 * The modal is presented within a focus trap for accessibility purposes - please note that the selector used for the focusTrap must be unique on the given page, otherwise focus may be trapped on the wrong element.
 *
 * @param {Object} props
 * @param {Array} props.children The content to be displayed inside the Modal. Can be provided by composition (see example).
 * @param {string} props.size The desired modal size ('s', 'm' or 'default')
 * @param {string} props.className Optional additional classnames to apply to the modal container
 * @param {string} props.title The title to be displayed in the modal heading. If provided, a title bar with a close button will be displayed.
 * @param {boolean} props.overlay Whether or not to show a semi-opaque overlay behind the modal
 * @param {Function} props.onClose  Callback for any function to be executed on close button click or Escape
 * @param {boolean} props.closeOnClickOutside Whether the modal should close if the user clicks outside of it
 * @param {string} props.focusTrapSelector The CSS selector for where to trap the user's focus. This should be unique to the page in which the modal is presented.
 * 
 * @example
 *  <Modal
      overlay={true}
      title="Example modal title"
      onClose={cancelAction}
      size="s"
      focusTrapSelector="#window-modal"
      closeOnClickOutside={false}
      className=".additional-class-name"
    >
      <div>
        <p>Some modal content</p>
      </div>
    </Modal>
 */
export const Modal = ({
  children,
  size = 'default',
  className,
  title,
  overlay = true,
  onClose = () => {},
  closeOnClickOutside = false,
  focusTrapSelector = '.crayons-modal',
}) => {
  return (
    <FocusTrap
      onDeactivate={onClose}
      clickOutsideDeactivates={closeOnClickOutside}
      selector={focusTrapSelector}
    >
      <div
        data-testid="modal-container"
        className={`crayons-modal${getAdditionalClassNames({
          size,
          className,
        })}`}
      >
        <div
          role="dialog"
          aria-modal="true"
          aria-label="modal"
          className="crayons-modal__box"
        >
          {title && (
            <div className="crayons-modal__box__header">
              <h2>{title}</h2>
              <Button
                icon={CloseIcon}
                variant="ghost"
                contentType="icon"
                aria-label="Close"
                onClick={onClose}
              />
            </div>
          )}
          <div className="crayons-modal__box__body">{children}</div>
        </div>
        {overlay && (
          <div
            data-testid="modal-overlay"
            className={`crayons-modal__overlay ${
              closeOnClickOutside ? 'background-clickable' : ''
            }`}
          />
        )}
      </div>
    </FocusTrap>
  );
};

Modal.displayName = 'Modal';

Modal.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  className: PropTypes.string,
  title: PropTypes.string.isRequired,
  overlay: PropTypes.bool,
  onClose: PropTypes.func,
  size: PropTypes.oneOf(['default', 's', 'm']).isRequired,
  focusTrapSelector: PropTypes.string,
};
