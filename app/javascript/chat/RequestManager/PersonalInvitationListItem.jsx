import { h } from 'preact';
import PropTypes from 'prop-types';
import { Trans } from 'react-i18next';
import { i18next } from '../../i18n/l10n';

import { Button } from '@crayons';

export const PendingInvitationListItem = ({ request, updateMembership }) => (
  <div className="crayons-card mb-6">
    <div className="crayons-card__body channel-request-card">
      <div className="request-message d-flex flex-wrap">
        <Trans i18nKey="chat.join.got" values={{channel: request.chat_channel_name}} />
      </div>
      <div className="request-actions">
        <Button
          className="m-2"
          size="s"
          variant="danger"
          onClick={updateMembership}
          data-channel-id={request.chat_channel_id}
          data-membership-id={request.membership_id}
          data-channel-slug={request.slug}
          data-user-action="reject"
        >
          {i18next.t('chat.join.reject')}
        </Button>
        <Button
          className="m-2"
          size="s"
          onClick={updateMembership}
          data-channel-id={request.chat_channel_id}
          data-membership-id={request.membership_id}
          data-channel-slug={request.slug}
          data-user-action="accept"
        >
          {i18next.t('chat.join.accept')}
        </Button>
      </div>
    </div>
  </div>
);

PendingInvitationListItem.propTypes = {
  request: PropTypes.arrayOf(
    PropTypes.shape({
      name: PropTypes.string.isRequired,
      membership_id: PropTypes.number.isRequired,
      user_id: PropTypes.number.isRequired,
      role: PropTypes.string.isRequired,
      image: PropTypes.string.isRequired,
      username: PropTypes.string.isRequired,
      status: PropTypes.string.isRequired,
      chat_channel_name: PropTypes.string.isRequired,
    }),
  ).isRequired,
  updateMembership: PropTypes.func.isRequired,
};
