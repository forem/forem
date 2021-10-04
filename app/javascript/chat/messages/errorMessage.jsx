import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '../../i18n/l10n';

export const ErrorMessage = ({ message }) => {
  const errorStyle = { color: 'darksalmon', 'font-size': '13px' };
  return (
    <div className="chatmessage">
      <span
        className="chatmessage__body"
        style={errorStyle}
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{
          __html: i18next.t('chat.messages.sorry', {
            user: window.currentUser.username,
            message,
          }),
        }}
      />
    </div>
  );
};

ErrorMessage.propTypes = {
  message: PropTypes.string.isRequired,
};
