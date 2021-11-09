import { h } from 'preact';
import SVG from 'react-inlinesvg';
import classNames from 'classnames/bind';

export const Icon = (props) => {
  const { src, native, className, ...otherProps } = props;

  return (
    <SVG
      src={src}
      className={classNames('crayons-icon', {
        'crayons-icon--default': native,
        [className]: className,
      })}
      {...otherProps}
    />
  );
};

Icon.displayName = 'Icon';
