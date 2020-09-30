import { h } from 'preact';
import PropTypes from 'prop-types';

const ActiveChannelMemberList = ({
  showMemberlist,
  activeChannelId,
  channelUsers,
  memberFilterQuery,
  addUserName,
}) => {
  const filterRegx = new RegExp(memberFilterQuery, 'gi');

  return (
    <div
      className={
        showMemberlist ? 'mention__list mention__visible' : 'mention__list'
      }
      id="mentionList"
    >
      {showMemberlist && channelUsers
        ? Object.values(channelUsers[activeChannelId])
            .filter((user) => user.username.match(filterRegx))
            .map((user) => (
              <div
                key={user.username}
                className="mention__user"
                role="button"
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
                  {'@'}
                  {user.username}
                  <p>{user.name}</p>
                </span>
              </div>
            ))
        : ' '}
    </div>
  );
};

ActiveChannelMemberList.propTypes = {
  showMemberlist: PropTypes.bool,
  activeChannelId: PropTypes.number,
  channelUsers: PropTypes.array,
  memberFilterQuery: PropTypes.string,
  addUserName: PropTypes.func,
};

export default ActiveChannelMemberList;
