import { h } from 'preact';
import classNames from 'classnames/bind';
import { Button2, Link } from '@crayons';

export const Tab = (props) => {
  const {
    className,
    current,
    control,
    ...otherProps
  } = props;

  const classes = classNames('c-tab', {
    [className]: className,
  });

  const linkCurrentProps = current && {'aria-current': 'page'};
  const buttonCurrentProps = current ? {'aria-pressed': true} : {'aria-pressed': false};

  return control === 'buttons' ? (
    <Button2 className={classes} {...buttonCurrentProps} {...otherProps} />
  ) : (
    <Link block className={classes} {...linkCurrentProps} {...otherProps} />
  );
};

Tab.displayName = 'Tab';
