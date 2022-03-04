import { h } from 'preact';
import PropTypes from 'prop-types';
import { useState } from 'preact/hooks';
import classNames from 'classnames/bind';
import { Icon } from '@crayons';
import XIcon from '@images/x.svg';

export const Pill = ({
  children,
  descriptionIcon,
  actionIcon,
  destructiveActionIcon,
  className,
  tooltip,
  onKeyUp,
  onClick,
  noAction,
  ...otherProps
}) => {
  const [suppressTooltip, setSuppressTooltip] = useState(false);

  const handleKeyUp = (event) => {
    onKeyUp?.(event);
    if (!tooltip) {
      return;
    }
    setSuppressTooltip(event.key === 'Escape');
  };

  const classes = classNames('c-pill', {
    'c-pill--description-icon': descriptionIcon,
    'c-pill--action-icon': actionIcon || destructiveActionIcon,
    'c-pill--action-icon--destructive': destructiveActionIcon,
    'crayons-tooltip__activator': tooltip,
    'cursor-default': noAction,
    'cursor-help': tooltip && noAction,
    [className]: className,
  });

  return (
    <button
      className={classes}
      type="button"
      onKeyUp={handleKeyUp}
      aria-disabled={noAction}
      onClick={noAction ? null : onClick}
      {...otherProps}
    >
      {descriptionIcon && (
        <Icon
          aria-hidden="true"
          focusable="false"
          width={18}
          height={18}
          src={descriptionIcon}
          className="c-pill__description-icon"
        />
      )}
      {children}
      {(actionIcon || destructiveActionIcon) && (
        <Icon
          aria-hidden="true"
          focusable="false"
          width={18}
          height={18}
          src={actionIcon || (destructiveActionIcon && XIcon)}
          className="c-pill__action-icon"
        />
      )}
      {tooltip && (
        <span
          data-testid="tooltip"
          className={classNames('crayons-tooltip__content', {
            'crayons-tooltip__suppressed': suppressTooltip,
          })}
        >
          {tooltip}
        </span>
      )}
    </button>
  );
};

Pill.displayName = 'Pill';

Pill.propTypes = {
  children: PropTypes.string.isRequired,
  className: PropTypes.string,
  descriptionIcon: PropTypes.elementType,
  actionIcon: PropTypes.elementType,
  destructiveActionIcon: PropTypes.bool,
  noAction: PropTypes.bool,
  tooltip: PropTypes.oneOfType([PropTypes.string, PropTypes.node]),
};
