import { h, cloneElement } from 'preact';
import classNames from 'classnames/bind';

export const Tabs = (props) => {
  const {
    children,
    scrollable,
    className,
    control = 'buttons',
    ...otherProps
  } = props;

  const Wrapper = control === 'buttons' ? 'div' : 'nav';

  const classes = classNames('c-tabs', {
    'c-tabs--scrollable': scrollable,
    [className]: className,
  });

  return (
    <Wrapper className={classes} {...otherProps}>
      {children.map(tab => {
        return cloneElement(tab, { control })
      })}
    </Wrapper>
  );
};

Tabs.displayName = 'Tabs';
