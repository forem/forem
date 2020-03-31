import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';

// crayons-btn--full

function getAdditionalClassNames({
  className,
  isFull,
  isSecondary,
  isOutlined,
  isDanger,
  hasLeftIcon,
}) {
  let additionalClassNames = '';

  if (isSecondary) {
    additionalClassNames += ' crayons-btn--secondary';
  }

  if (isOutlined) {
    additionalClassNames += ' crayons-btn--outlined';
  }

  if (isDanger) {
    additionalClassNames += ' crayons-btn--danger';
  }

  if (isFull) {
    additionalClassNames += ' crayons-btn--full';
  }

  if (hasLeftIcon) {
    additionalClassNames += ' crayons-btn--icon-left';
  }

  if (className && className.length > 0) {
    additionalClassNames += ` ${className}`;
  }

  return additionalClassNames;
}

export const Button = ({
  children,
  url = '#',
  className,
  isFull = false,
  isSecondary = false,
  isOutlined = false,
  isDanger = false,
  hasLeftIcon = false,
}) => (
  <a
    href={url}
    className={`crayons-btn ${getAdditionalClassNames({
      className,
      isFull,
      isOutlined,
      isSecondary,
      isDanger,
      hasLeftIcon,
    })}`}
  >
    {children}
  </a>
);

Button.displayName = 'Button';

Button.defaultProps = {
  className: undefined,
};

Button.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  url: PropTypes.string.isRequired,
  className: PropTypes.string,
  isFull: PropTypes.bool.isRequired,
  isSecondary: PropTypes.bool.isRequired,
  isOutlined: PropTypes.bool.isRequired,
  isDanger: PropTypes.bool.isRequired,
  hasLeftIcon: PropTypes.bool.isRequired,
};
