import { h } from 'preact';
import PropsType from 'prop-types';

const LeaveMembershipSection = ({ handleleaveChatChannelMembership }) => {
  return (
    <div className="crayons-card p-4 grid gap-2 mb-4 leave_membership_section">
      <h3>Danger Zone</h3>
      <div>
        <button
          className="crayons-btn crayons-btn--danger leave_button"
          type="submit"
          onClick={handleleaveChatChannelMembership}
        >
          Leave Channel
        </button>
      </div>
    </div>
  );
};

LeaveMembershipSection.propTypes = {
  handleleaveChatChannelMembership: PropsType.func.isRequired,
};

export default LeaveMembershipSection;
