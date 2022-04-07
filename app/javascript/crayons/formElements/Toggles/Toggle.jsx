import { h } from 'preact';

export const Toggle = ({ ...otherProps }) => {
  return (
    <div class="c-toggle">
      <input type="checkbox" {...otherProps} />
      <span class="c-toggle__control" />
    </div>
  );
};

Toggle.displayName = 'Toggle';
