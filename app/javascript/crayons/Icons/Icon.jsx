import { h } from 'preact';
import PropTypes from 'prop-types';
import classNames from 'classnames/bind';

export const Icon = (props) => {
  const { src: InternalIcon, native, className, ...otherProps } = props;

  return (
    <InternalIcon
      className={classNames('crayons-icon', {
        'crayons-icon--default': native,
        [className]: className,
      })}
      {...otherProps}
    />
  );
};

Icon.displayName = 'Icon';

Icon.propTypes = {
  native: PropTypes.bool,
  className: PropTypes.string,
  src: PropTypes.ReactNode,
};
