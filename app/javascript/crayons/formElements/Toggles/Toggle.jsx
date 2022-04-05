import { h } from 'preact';
import PropTypes from 'prop-types';

export const Toggle = ({ description, ...otherProps }) => {
  return (
    <label class="c-toggle" aria-label={description}>
      <input type="checkbox" {...otherProps} />
      <span class="c-toggle__control" />
    </label>
  );
};

Toggle.displayName = 'Toggle';

Toggle.propTypes = {
  description: PropTypes.string.isRequired,
};
