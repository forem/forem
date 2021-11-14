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
      {children.map((tab) => {
        return cloneElement(tab, { elements, fitted });
      })}
    </Wrapper>
  );
};

Tabs.displayName = 'Tabs';
