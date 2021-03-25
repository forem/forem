import { h } from 'preact';
import PropTypes from 'prop-types';

export const Alert = ({ showAlert }) => {
  const otherClassname = showAlert ? '' : 'chatalert__default--hidden';

  return (
    <div
      role="alert"
      aria-hidden={!showAlert}
      className={`chatalert__default ${otherClassname}`}
    >
      More new messages below
    </div>
  );
};

Alert.propTypes = {
  showAlert: PropTypes.bool.isRequired,
};
