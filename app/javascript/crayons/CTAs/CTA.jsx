import { h } from 'preact';
import PropTypes from 'prop-types';
import classNames from 'classnames/bind';
import { defaultChildrenPropTypes } from '../../common-prop-types/default-children-prop-types';
import { Icon } from '@crayons';

export const CTA = (props) => {
  const {
    children,
    href = '#',
    variant = 'default',
    icon,
    className,
    ...otherProps
  } = props;

  const classes = classNames('c-cta', {
    [`c-cta--${variant}`]: variant && variant !== 'default',
    'c-cta--icon-left': icon && children,
    [className]: className,
  });

  return (
    <a href={href} className={classes} {...otherProps}>
      {icon && (
        <Icon
          src={icon}
          aria-hidden="true"
          focusable="false"
          className="c-cta__icon"
        />
      )}
      {children}
    </a>
  );
};

CTA.displayName = 'CTA';

CTA.propTypes = {
  variant: PropTypes.oneOf(['default', 'branded']),
  rounded: PropTypes.bool,
  href: PropTypes.string.isRequired,
  className: PropTypes.string,
  children: defaultChildrenPropTypes.isRequired,
  icon: PropTypes.elementType,
};
