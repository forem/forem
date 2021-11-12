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

  const sharedProps = {
    className: classes
  }
  const buttonCurrentProps = current ? {'aria-pressed': true} : {'aria-pressed': false};
  const linkCurrentProps = current && {'aria-current': 'page'};

  return control === 'buttons' ? (
    <ButtonNew {...sharedProps} {...buttonCurrentProps} {...otherProps} />
  ) : (
    <Link block {...sharedProps} {...linkCurrentProps} {...otherProps} />
  );
};

Tab.displayName = 'Tab';
