import { h, cloneElement } from 'preact';
import PropTypes from 'prop-types';
import classNames from 'classnames/bind';
import { defaultChildrenPropTypes } from '../../common-prop-types/default-children-prop-types';

export const Tabs = ({
  children,
  stacked,
  fitted,
  title,
  className,
  elements = 'buttons',
  ...otherProps
}) => {
  const classes = classNames('c-tabs', {
    'c-tabs--stacked': stacked,
    'c-tabs--fitted': fitted,
    [className]: className,
  });

  return (
    <nav className={classes} aria-label={title} {...otherProps}>
      <ul className="c-tabs__list">
        {children.map((tab) => (
          <li key={tab} className="c-tabs__list__item">
            {cloneElement(tab, { elements, fitted })}
          </li>
        ))}
      </ul>
    </nav>
  );
};

Tabs.displayName = 'Tabs';

Tabs.propTypes = {
  children: defaultChildrenPropTypes,
  stacked: PropTypes.bool,
  fitted: PropTypes.bool,
  elements: PropTypes.oneOf(['buttons', 'links']),
  className: PropTypes.string,
  title: PropTypes.string.isRequired,
};
