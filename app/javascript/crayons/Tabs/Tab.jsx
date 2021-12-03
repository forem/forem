import { h } from 'preact';
import classNames from 'classnames/bind';
import { ButtonNew as Button, Link } from '@crayons';

export const Tab = ({ className, current, elements, fitted, ...otherProps }) => {

  const classes = classNames('c-tab', {
    'c-tab--fitted': fitted,
    [className]: className,
  });

  const sharedProps = {
    className: classes,
  };
  const buttonCurrentProps = { 'aria-pressed': !!current }
  const linkCurrentProps = current && { 'aria-current': 'page' };

  return elements === 'buttons' ? (
    <Button {...sharedProps} {...buttonCurrentProps} {...otherProps} />
  ) : (
    <Link block {...sharedProps} {...linkCurrentProps} {...otherProps} />
  );
};

Tab.displayName = 'Tab';
