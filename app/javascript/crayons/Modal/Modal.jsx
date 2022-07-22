import { h } from 'preact';
import PropTypes from 'prop-types';
import classNames from 'classnames/bind';
import { FocusTrap } from '../../shared/components/focusTrap';
import { defaultChildrenPropTypes } from '../../common-prop-types';
import { ButtonNew as Button } from '@crayons';
import CloseIcon from '@images/x.svg';

export const Modal = ({
  children,
  size,
  className,
  title,
  prompt,
  sheet,
  centered,
  noBackdrop,
  showHeader = true,
  sheetAlign = 'center',
  backdropDismissible = false,
  allowOverflow = false,
  onClose = () => {},
  focusTrapSelector = '.crayons-modal__box',
  document = window.document,
}) => {
  const classes = classNames('crayons-modal', {
    [`crayons-modal--${size}`]: size && size !== 'medium',
    [`crayons-modal--${sheetAlign}`]: sheet && sheetAlign !== 'center',
    'crayons-modal--sheet': sheet,
    'crayons-modal--prompt': prompt,
    'crayons-modal--centered': centered && prompt,
    'crayons-modal--bg-dismissible': !noBackdrop && backdropDismissible,
    'crayons-modal--overflow-visible': allowOverflow,
    [className]: className,
  });

  return (
    <FocusTrap
      onDeactivate={onClose}
      clickOutsideDeactivates={backdropDismissible}
      selector={focusTrapSelector}
      document={document}
    >
      <div data-testid="modal-container" className={classes}>
        <div
          role="dialog"
          aria-modal="true"
          aria-label="modal"
          className="crayons-modal__box"
        >
          {showHeader && (
            <header className="crayons-modal__box__header">
              <h2 class="crayons-subtitle-2">{title}</h2>
              <Button
                icon={CloseIcon}
                aria-label="Close"
                className="crayons-modal__dismiss"
                onClick={onClose}
              />
            </header>
          )}
          <div className="crayons-modal__box__body">{children}</div>
        </div>
        {!noBackdrop && (
          <div
            data-testid="modal-overlay"
            className="crayons-modal__backdrop"
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
  backdrop: PropTypes.bool,
  backdropDismissible: PropTypes.bool,
  prompt: PropTypes.bool,
  centered: PropTypes.bool,
  onClose: PropTypes.func,
  size: PropTypes.oneOf(['small', 'medium', 'large']),
  focusTrapSelector: PropTypes.string,
  sheet: PropTypes.bool,
  sheetAlign: PropTypes.oneOf(['center', 'left', 'right']),
  showHeader: PropTypes.bool,
};
