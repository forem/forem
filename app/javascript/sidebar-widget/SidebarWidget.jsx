import { h, Fragment } from 'preact';
import { useCallback, useEffect, useState } from 'preact/hooks';
import sendFollowUser from '../utilities/sendFollowUser';
import SidebarUser from './sidebarUser';

const SidebarWidget = () => {
  const [suggestedUsers, setSuggestedUsers] = useState([]);

  useEffect(() => {
    const tagInfo =
      JSON.parse(
        document.getElementById('sidebarWidget__pack').dataset.tagInfo,
      ) || {};

    // Fetching suggested users
    fetch(`/users?state=sidebar_suggestions&tag=${tagInfo.name}`, {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    })
      .then((response) => response.json())
      .then((json) => {
        setSuggestedUsers(json);
      })
      .catch((error) => {
        setSuggestedUsers([]);
        Honeybadger.notify(error);
      });
  }, []);

  const followUser = useCallback(
    (user) => {
      const updatedUser = user;
      const updatedSuggestedUsers = suggestedUsers;
      const userIndex = suggestedUsers.indexOf(user);

      const followBtn = document.getElementById(
        `widget-list-item__follow-button-${updatedUser.username}`,
      );
      followBtn.innerText = updatedUser.following ? 'Follow' : 'Following';

      const toggleFollowState = (newFollowState) => {
        updatedUser.following = newFollowState === 'followed';
        updatedSuggestedUsers[userIndex] = updatedUser;
        setSuggestedUsers(updatedSuggestedUsers);
      };
      sendFollowUser(user, toggleFollowState);
    },
    [suggestedUsers, setSuggestedUsers],
  );

  if (suggestedUsers.length > 0) {
    return (
      <div className="widget" id="widget-00001">
        <div className="widget-suggested-follows-container">
          <header>
            <h4>who to follow</h4>
          </header>
          <div className="widget-body">
            {suggestedUsers.map((user, index) => (
              <SidebarUser
                key={user.id}
                user={user}
                followUser={followUser}
                index={index}
              />
            ))}
          </div>
        </div>
      </div>
    );
  }
  return <Fragment />;
};

export default SidebarWidget;
