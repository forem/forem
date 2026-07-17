import { h } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import { sendFollowUser } from '../utilities/sendFollowUser';
import { SidebarUser } from './sidebarUser';

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

    if (updatedUser.following) {
      followBtn.innerText = 'Follow';
      followBtn.classList.remove('crayons-btn--outlined');
      followBtn.classList.add('crayons-btn--secondary');
    } else {
      followBtn.innerText = 'Following';
      followBtn.classList.remove('crayons-btn--secondary');
      followBtn.classList.add('crayons-btn--outlined');
    }

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
    <section className="crayons-card crayons-card--secondary crayons-layout__content mb-4" id="widget-00001">
      <header className="crayons-card__header">
        <h3 className="crayons-subtitle-3">who to follow</h3>
      </header>
      <div className="crayons-card__body">
        {suggestedUsers.map((user) => (
          <SidebarUser key={user.id} user={user} followUser={followUser} />
        ))}
      </div>
    </section>
  );
};
