import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';

function getAdditionalClassNames({ variant, className, icon }) {
  let additionalClassNames = '';

  if (variant && variant.length > 0 && variant !== 'primary') {
    additionalClassNames += ` crayons-btn--${variant}`;
  }

  if (icon) {
    additionalClassNames += ' crayons-btn--icon-left';
  }

  if (className && className.length > 0) {
    additionalClassNames += ` ${className}`;
  }

  return additionalClassNames;
}

export const Button = ({
  children,
  variant = 'primary',
  as = 'button',
  className,
  icon,
  url,
  buttonType,
}) => {
  const ComponentName = as;
  const Icon = icon;
  const otherProps = as === 'button' ? { type: buttonType } : { href: url };

  return (
    <ComponentName
      className={`crayons-btn ${getAdditionalClassNames({
        variant,
        className,
        icon,
      })}`}
      {...otherProps}
    >
      {Icon && <Icon />}
      {children}
    </ComponentName>
  );
};

Button.displayName = 'Button';

Button.defaultProps = {
  className: undefined,
  icon: undefined,
  url: undefined,
  buttonType: 'button',
};

Button.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  variant: PropTypes.oneOf(['primary', 'secondary', 'outlined', 'danger'])
    .isRequired,
  as: PropTypes.oneOf(['a', 'button']).isRequired,
  className: PropTypes.string,
  icon: PropTypes.node,
  url: PropTypes.string,
  buttonType: PropTypes.string,
};
