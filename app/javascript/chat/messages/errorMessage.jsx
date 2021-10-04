import { h } from 'preact';
import PropTypes from 'prop-types';
import { Trans } from 'react-i18next';

export const ErrorMessage = ({ message }) => {
  const errorStyle = { color: 'darksalmon', 'font-size': '13px' };
  return (
    <div className="chatmessage">
      <span className="chatmessage__body" style={errorStyle}>
        <Trans i18nKey="chat.messages.sorry" values={{user: window.currentUser.username, message}}
          // eslint-disable-next-line react/jsx-key
          components={[<span className="chatmessagebody__currentuser" />]} />
      </span>
    </div>
  );
};

ErrorMessage.propTypes = {
  message: PropTypes.string.isRequired,
};
