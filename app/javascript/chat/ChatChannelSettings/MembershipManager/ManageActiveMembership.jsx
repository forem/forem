import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { defaulMembershipPropType } from '../../../common-prop-types/membership-prop-type';
import MembershipSection from './MembershipSection';

export default class ManageActiveMembership extends Component {
  static propTypes = {
    activeMemberships: PropTypes.arrayOf(defaulMembershipPropType).isRequired,
    currentMembership: PropTypes.isRequired,
    invitationLink: PropTypes.string.isRequired,
    removeMembership: PropTypes.func.isRequired,
    handleUpdateMembershipRole: PropTypes.func.isRequired,
  };

  constructor(props) {
    super(props);
    this.state = {
      activeMemberships: props.activeMemberships,
      searchMembers: null,
      listAllMemberShips: props.activeMemberships,
      currentMembership: props.currentMembership,
      invitationLink: props.invitationLink,
      removeMembership: props.removeMembership,
      handleUpdateMembershipRole: props.handleUpdateMembershipRole,
    };
  }

  componentWillReceiveProps() {
    const {
      activeMemberships,
      currentMembership,
      removeMembership,
      invitationLink,
    } = this.props;
    this.setState({
      listAllMemberShips: activeMemberships,
      currentMembership,
      invitationLink,
      removeMembership,
      activeMemberships,
    });
  }

  searchTheMembershipUser = (e) => {
    const query = e.target?.value?.toLowerCase();

    this.setState((prevState) => {
      const filteredActiveMemberships = prevState.activeMemberships.filter(
        (activeMembership) => {
          const value = activeMembership.name.toLowerCase();
          return value.includes(query);
        },
      );

      return {
        searchMembers: query,
        listAllMemberShips: filteredActiveMemberships,
      };
    });
  };

  render() {
    const {
      searchMembers,
      listAllMemberShips,
      currentMembership,
      removeMembership,
      handleUpdateMembershipRole,
    } = this.state;

    return (
      <div className="pt-3">
        <div className="p-4 grid gap-2 crayons-card my-4 mx-auto membership-manager">
          <h2 className="text-title">Chat Channel Membership manager</h2>
        </div>
        <div className="p-4 grid gap-2 crayons-card my-4">
          <input
            type="text"
            className="crayons-textfield"
            placeholder="Search Member..."
            value={searchMembers}
            name="search-members"
            onKeyUp={this.searchTheMembershipUser.bind(this)}
            aria-label="search memberships"
          />
          <div
            data-spy="scroll"
            data-offset="5"
            className="chat_channel-member-list"
          >
            <MembershipSection
              memberships={listAllMemberShips}
              currentMembership={currentMembership}
              removeMembership={removeMembership}
              handleUpdateMembershipRole={handleUpdateMembershipRole}
            />
          </div>
        </div>
      </div>
    );
  }
}
