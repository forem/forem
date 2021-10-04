import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '@utilities/locale';

export const ChannelDescriptionSection = ({
  channelName,
  channelDescription,
  currentMembershipRole,
}) => {
  return (
    <div className="p-4 grid gap-2 crayons-card mb-4 channel_details">
      <h2 className="mb-1 channel_title">{channelName}</h2>
      <p>{channelDescription}</p>
      <p className="fw-bold">
        {i18next.t('chat.settings.role', { role: currentMembershipRole })}
      </p>
    </div>
  );
};

ChannelDescriptionSection.propTypes = {
  channelName: PropTypes.string.isRequired,
  currentMembershipRole: PropTypes.string.isRequired,
  channelDescription: PropTypes.string.isRequired,
};
