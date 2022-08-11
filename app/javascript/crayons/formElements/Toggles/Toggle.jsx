import { h } from 'preact';

export const Toggle = ({ ...otherProps }) => {
  return <input type="checkbox" className="c-toggle" {...otherProps} />;
};

Toggle.displayName = 'Toggle';
