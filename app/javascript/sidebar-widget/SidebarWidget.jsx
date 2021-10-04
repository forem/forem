import { h } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import { sendFollowUser } from '../utilities/sendFollowUser';
import { SidebarUser } from './sidebarUser';
import { i18next } from '@utilities/locale';

export const SidebarWidget = () => {
  const [suggestedUsers, setSuggestedUsers] = useState([]);

  useEffect(() => {
    const tagInfo = JSON.parse(
      document.getElementById('sidebarWidget__pack').dataset.tagInfo,
    );

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

  const followUser = (user) => {
    const updatedUser = user;
    const updatedSuggestedUsers = suggestedUsers;
    const userIndex = suggestedUsers.indexOf(user);

    const followBtn = document.getElementById(
      `widget-list-item__follow-button-${updatedUser.username}`,
    );
    followBtn.innerText = i18next.t(
      `onboarding.user.${updatedUser.following ? 'follow' : 'following'}`,
    );

    const toggleFollowState = (newFollowState) => {
      updatedUser.following = newFollowState === 'followed';
      updatedSuggestedUsers[userIndex] = updatedUser;
      setSuggestedUsers(updatedSuggestedUsers);
    };
    sendFollowUser(user, toggleFollowState);
  };

  if (suggestedUsers.length === 0) {
    return null;
  }

  return (
    <div className="widget" id="widget-00001">
      <div className="widget-suggested-follows-container">
        <header>
          <h4>{i18next.t('main.who')}</h4>
        </header>
        <div className="widget-body">
          {suggestedUsers.map((user) => (
            <SidebarUser key={user.id} user={user} followUser={followUser} />
          ))}
        </div>
      </div>
    </div>
  );
};
