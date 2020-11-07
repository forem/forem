import { h } from 'preact';
import PropsType from 'prop-types';
import { Button } from '@crayons';

/**
 * This component render the Leave chat channel membership actions
 *
 * @param {object} props
 * @param {function} handleleaveChannelMembership
 * @param {string} currentMembershipRole
 *
 * @component
 *
 * @example
 *
 * <LeaveMembershipSection
 *   handleleaveChannelMembership={handleleaveChannelMembership}
 *   currentMembershipRole={currentMembershipRole}
 * />
 *
 */
export default function LeaveMembershipSection({
  handleleaveChannelMembership,
  currentMembershipRole,
}) {
  if (currentMembershipRole === 'mod') {
    return null;
  }

  return (
    <div className="crayons-card p-4 grid gap-2 mb-4 leave_membership_section">
      <h3>Danger Zone</h3>
      <div>
        <Button
          className="leave_button"
          variant="danger"
          type="submit"
          onClick={handleleaveChannelMembership}
        >
          Leave Channel
        </Button>
      </div>
    </div>
  );
}

LeaveMembershipSection.propTypes = {
  handleleaveChannelMembership: PropsType.func.isRequired,
};
