import { h } from 'preact';
import classNames from 'classnames/bind';
import { ButtonNew, Link } from '@crayons';

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

  const buttonCurrentProps = current ? {'aria-pressed': true} : {'aria-pressed': false};
  const linkCurrentProps = current && {'aria-current': 'page'};

  return control === 'buttons' ? (
    <ButtonNew className={classes} {...buttonCurrentProps} {...otherProps} />
  ) : (
    <Link block className={classes} {...linkCurrentProps} {...otherProps} />
  );
};

Tab.displayName = 'Tab';
