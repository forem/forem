import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';

/**
 * This component is used to render the list of all Active chat channel Members
 * in the mention list
 * 
 * @param {object} props
 * @param {booleam} props.showMemberlist
 * @param {number} props.activeChannelId
 * @param {object} props.channelUsers
 * @param {string} props.memberFilterQuery
 * @param {function} props.addUserName
 * 
 * @component
 * 
 * @example
 * 
 * <ActiveChannelMemberList 
 *  showMemberlist={showMemberlist}
    activeChannelId={activeChannelId}
    channelUsers={channelUsers}
    memberFilterQuery={memberFilterQuery}
    addUserName={addUserName}
 * />
 * 
 */

function ActiveChannelMemberList({
  showMemberlist,
  activeChannelId,
  channelUsers,
  memberFilterQuery,
  addUserName,
}) {
  const filterRegx = new RegExp(memberFilterQuery, 'gi');

  return (
    <div
      className={
        showMemberlist ? 'mention__list mention__visible' : 'mention__list'
      }
      id="mentionList"
    >
      {showMemberlist
        ? Object.values(channelUsers[activeChannelId])
            .filter((user) => user.username.match(filterRegx))
            .map((user) => (
              <Button
                key={user.username}
                className="mention__user crayons-btn--ghost w-100 align-left"
                onClick={(e) => addUserName(e)}
                tabIndex="0"
                data-content={user.username}
                onKeyUp={(e) => {
                  if (e.keyCode === 13) addUserName(e);
                }}
              >
                <img
                  className="mention__user__image"
                  src={user.profile_image}
                  alt={user.name}
                  style={!user.profile_image ? { display: 'none' } : ' '}
                />
                <span
                  style={{
                    padding: '3px 0px',
                    'font-size': '16px',
                  }}
                >
                  {`@${user.username}`}
                  <p>{user.name}</p>
                </span>
              </Button>
            ))
        : ' '}
    </div>
  );
}

ActiveChannelMemberList.propTypes = {
  showMemberlist: PropTypes.bool,
  activeChannelId: PropTypes.number,
  channelUsers: PropTypes.array,
  memberFilterQuery: PropTypes.string,
  addUserName: PropTypes.func,
};

export default ActiveChannelMemberList;
