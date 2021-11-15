import { h } from 'preact';
import PropTypes from 'prop-types';
import classNames from 'classnames/bind';
import { Link } from '@crayons';

export const CTA = (props) => {
  const { style = 'default', className, ...otherProps } = props;

  const classes = classNames('c-cta', {
    [`c-cta--${style}`]: style,
    [className]: className,
  });

  return <Link block className={classes} {...otherProps} />;
};

CTA.displayName = 'CTA';

CTA.propTypes = {
  style: PropTypes.oneOf(['default', 'branded']),
  className: PropTypes.string,
};
