import { h, cloneElement } from 'preact';
import classNames from 'classnames/bind';
import PropTypes from 'prop-types';
import { defaultChildrenPropTypes } from '../../common-prop-types/default-children-prop-types';

export const Tabs = ({
  children,
  stacked,
  fitted,
  className,
  elements = 'buttons',
  ...otherProps
}) => {
  const Wrapper = elements === 'buttons' ? 'div' : 'nav';

  const classes = classNames('c-tabs', {
    'c-tabs--stacked': stacked,
    'c-tabs--fitted': fitted,
    [className]: className,
  });

  return (
    <Wrapper className={classes} {...otherProps}>
      <ul className="c-tabs__list">
        {children.map((tab) => (
          <li key={tab} className="c-tabs__list__item">
            {cloneElement(tab, { elements, fitted })}
          </li>
        ))}
      </ul>
    </Wrapper>
  );
};

Tabs.displayName = 'Tabs';

Tabs.propTypes = {
  elements: PropTypes.oneOf(['buttons', 'links']),
  stacked: PropTypes.bool,
  fitted: PropTypes.bool,
  className: PropTypes.string,
  children: defaultChildrenPropTypes,
};
