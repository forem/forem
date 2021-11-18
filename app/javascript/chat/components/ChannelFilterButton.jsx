import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

/**
 * This component renders a button that is used for filtering chat channels.
 *
 * @param {object} props
 * @param {string} props.type - The type of chat channel selected
 * @param {string} props.name - Used for testing and is displayed to the user on the button
 * @param {boolean} props.active - Should the button have the `active` CSS class`?
 * @param {function} props.onClick - Fired with the onClick trigger
 *
 * @component
 *
 * @example
 * <ChannelFilterButton
 *   type="all"
 *   name="all"
 *   active={state.channelTypeFilter === 'all'}
 *   onClick={this.triggerChannelTypeFilter}
 * />
 */

export function ChannelFilterButton({ type, name, active, onClick }) {
  return (
    <Button
      data-channel-type={type}
      data-testid={name}
      onClick={onClick}
      className={`chat__channeltypefilterbutton crayons-indicator crayons-indicator--${
        active ? 'accent' : ''
      }`}
    >
      {name}
    </Button>
  );
}

ChannelFilterButton.propTypes = {
  type: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  active: PropTypes.bool.isRequired,
  onClick: PropTypes.func.isRequired,
};
