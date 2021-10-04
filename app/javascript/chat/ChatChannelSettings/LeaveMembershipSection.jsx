import { h } from 'preact';
import PropsType from 'prop-types';
import { i18next } from '@utilities/locale';
import { Button } from '@crayons';

export const LeaveMembershipSection = ({
  handleleaveChannelMembership,
  currentMembershipRole,
}) => {
  if (currentMembershipRole === 'mod') {
    return null;
  }

  return (
    <div className="crayons-card p-4 grid gap-2 mb-4 leave_membership_section">
      <h3>{i18next.t('common.danger')}</h3>
      <div>
        <Button
          className="leave_button"
          variant="danger"
          type="submit"
          onClick={handleleaveChannelMembership}
        >
          {i18next.t('chat.settings.leave_channel')}
        </Button>
      </div>
    </div>
  );
};

LeaveMembershipSection.propTypes = {
  handleleaveChannelMembership: PropsType.func.isRequired,
};
