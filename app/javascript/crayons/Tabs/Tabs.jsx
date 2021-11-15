import { h, cloneElement } from 'preact';
import classNames from 'classnames/bind';

export const Tabs = (props) => {
  const {
    children,
    stacked,
    fitted,
    className,
    elements = 'buttons',
    ...otherProps
  } = props;

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
