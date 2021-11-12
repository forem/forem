import { h, cloneElement } from 'preact';
import classNames from 'classnames/bind';

export const Tabs = (props) => {
  const {
    children,
    stacked,
    fitted,
    className,
    control = 'buttons',
    ...otherProps
  } = props;

  const Wrapper = control === 'buttons' ? 'div' : 'nav';

  const classes = classNames('c-tabs', {
    'c-tabs--stacked': stacked,
    'c-tabs--fitted': fitted,
    [className]: className,
  });

  return (
    <Wrapper className={classes} {...otherProps}>
      {children.map((tab) => {
        return cloneElement(tab, { control, fitted });
      })}
    </Wrapper>
  );
};

Tabs.displayName = 'Tabs';
