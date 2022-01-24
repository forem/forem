import { h } from 'preact';
import PropTypes from 'prop-types';
import { useState } from 'preact/hooks';
import classNames from 'classnames/bind';
import { defaultChildrenPropTypes } from '../../common-prop-types/default-children-prop-types';
import { Icon } from '@crayons';
import XIcon from '@images/x.svg';

export const Pill = ({
  children,
  element = 'button',
  iconLeft,
  iconRight,
  iconRightDestructive,
  className,
  tooltip,
  onKeyUp,
  ...otherProps
}) => {
  const Element = element;
  const restOfProps =
    element === 'button'
      ? { type: 'button', onKeyUp: handleKeyUp }
      : element === 'a'
      ? { href: '#' }
      : '';

  const [suppressTooltip, setSuppressTooltip] = useState(false);

  const handleKeyUp = (event) => {
    onKeyUp?.(event);
    if (!tooltip) {
      return;
    }
    setSuppressTooltip(event.key === 'Escape');
  };

  const classes = classNames('c-pill', {
    'c-pill--icon-left': iconLeft,
    'c-pill--icon-right': iconRight || iconRightDestructive,
    'c-pill--icon-right--destructive': iconRightDestructive,
    'crayons-tooltip__activator': tooltip,
    [className]: className,
  });

  return (
    <Element className={classes} {...otherProps} {...restOfProps}>
      {iconLeft && (
        <Icon
          aria-hidden="true"
          focusable="false"
          viewBox="0 0 24 24" // TODO:
          width={18}
          height={18}
          src={iconLeft}
          className="c-pill__icon-left"
        />
      )}
      {children}
      {(iconRight || iconRightDestructive) && (
        <Icon
          aria-hidden="true"
          focusable="false"
          width={18}
          height={18}
          src={iconRight || (iconRightDestructive && XIcon)}
          className="c-pill__icon-right"
        />
      )}
      {tooltip ? (
        <span
          data-testid="tooltip"
          className={classNames('crayons-tooltip__content', {
            'crayons-tooltip__suppressed': suppressTooltip,
          })}
        >
          {tooltip}
        </span>
      ) : null}
    </Element>
  );
};

Pill.displayName = 'Pill';

Pill.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  element: PropTypes.oneOf(['button', 'a', 'span', 'li']),
  className: PropTypes.string,
  iconLeft: PropTypes.elementType,
  iconRight: PropTypes.elementType,
  iconRightDestructive: PropTypes.bool,
  tooltip: PropTypes.oneOfType([PropTypes.string, PropTypes.node]),
};
