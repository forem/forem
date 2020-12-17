import { h } from 'preact';
import PropTypes from 'prop-types';
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

export const Modal = ({
  children,
  size = 'default',
  className,
  title,
  overlay,
  onClose,
}) => {
  return (
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
        {title.length > 0 && title && (
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
        <div data-testid="modal-overlay" className="crayons-modal__overlay" />
      )}
    </div>
  );
};

Modal.displayName = 'Modal';

Modal.defaultProps = {
  className: undefined,
  overlay: true,
  onClose: undefined,
};

Modal.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  className: PropTypes.string,
  title: PropTypes.string.isRequired,
  overlay: PropTypes.bool,
  onClose: PropTypes.func,
  size: PropTypes.oneOf(['default', 's', 'm']).isRequired,
};
