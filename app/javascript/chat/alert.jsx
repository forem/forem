import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '@utilities/locale';

export const Alert = ({ showAlert }) => {
  const otherClassname = showAlert ? '' : 'chatalert__default--hidden';

  return (
    <div
      role="alert"
      aria-hidden={!showAlert}
      className={`chatalert__default ${otherClassname}`}
    >
      {i18next.t('chat.more')}
    </div>
  );
};

Alert.propTypes = {
  showAlert: PropTypes.bool.isRequired,
};
