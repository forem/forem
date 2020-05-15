import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';
import { defaultChildrenPropTypes } from '../../common-prop-types';

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

export class Modal extends Component {
  state = {
    visible: true,
  };

  render() {
    const { visible } = this.state;
    const {
      children,
      size = 'default',
      className,
      title,
      overlay,
    } = this.props;

    const Icon = () => (
      <svg
        width="24"
        height="24"
        viewBox="0 0 24 24"
        className="crayons-icon"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" />
      </svg>
    );

    return visible ? (
      <div
        className={`crayons-modal${getAdditionalClassNames({
          size,
          className,
        })}`}
      >
        <div className="crayons-modal__box">
          {title.length > 0 && title && (
            <div className="crayons-modal__box__header">
              <h2>{title}</h2>
              <Button
                icon={Icon}
                variant="ghost"
                contentType="icon"
                title="Close"
                onClick={(_event) => {
                  this.setState({ visible: !visible });
                }}
              />
            </div>
          )}
          <div className="crayons-modal__box__body">{children}</div>
        </div>
        {overlay && <div className="crayons-modal__overlay" />}
      </div>
    ) : null;
  }
}

Modal.displayName = 'Modal';

Modal.defaultProps = {
  className: undefined,
  overlay: true,
};

Modal.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  className: PropTypes.string,
  title: PropTypes.string.isRequired,
  overlay: PropTypes.bool,
  size: PropTypes.oneOf(['default', 's', 'm']).isRequired,
};
