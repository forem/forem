import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

export const ChannelFilterButton = ({ type, name, active, onClick }) => {
  return (
    <Button
      data-channel-type={type}
      data-testid={name}
      onClick={onClick}
      className={`chat__channeltypefilterbutton crayons-indicator crayons-indicator--${
        type === active ? 'accent' : ''
      }`}
    >
      {name}
    </Button>
  );
};

ChannelFilterButton.propTypes = {
  type: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  active: PropTypes.bool.isRequired,
  onClick: PropTypes.func.isRequired,
};
