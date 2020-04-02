import { h } from 'preact';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types';

function getAdditionalClassNames({ variant, className, icon, disabled }) {
  let additionalClassNames = '';

  if (variant && variant.length > 0 && variant !== 'primary') {
    additionalClassNames += ` crayons-btn--${variant}`;
  }

  if (icon) {
    additionalClassNames += ' crayons-btn--icon-left';
  }

  if (disabled) {
    additionalClassNames += ' crayons-btn--disabled';
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
  disabled,
  onClick,
  onMouseOver,
  onMouseOut,
  onFocus,
  onBlur,
}) => {
  const ComponentName = as;
  const Icon = icon;
  const otherProps =
    as === 'button'
      ? { type: buttonType, disabled }
      : { href: disabled ? undefined : url };

  return (
    <ComponentName
      className={`crayons-btn${getAdditionalClassNames({
        variant,
        className,
        icon,
        disabled: as === 'a' && disabled,
      })}`}
      onClick={onClick}
      onMouseOver={onMouseOver}
      onMouseOut={onMouseOut}
      onFocus={onFocus}
      onBlur={onBlur}
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
  disabled: false,
  onClick: undefined,
  onMouseOver: undefined,
  onMouseOut: undefined,
  onFocus: undefined,
  onBlur: undefined,
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
  disabled: PropTypes.bool,
  onClick: PropTypes.func,
  onMouseOver: PropTypes.func,
  onMouseOut: PropTypes.func,
  onFocus: PropTypes.func,
  onBlur: PropTypes.func,
};
