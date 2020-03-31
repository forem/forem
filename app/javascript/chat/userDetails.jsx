import { h } from 'preact';
import { PropTypes } from 'prop-types';
// eslint-disable-next-line import/no-unresolved
import twitterImage from 'images/twitter-logo.svg';
// eslint-disable-next-line import/no-unresolved
import githubImage from 'images/github-logo.svg';
// eslint-disable-next-line import/no-unresolved
import websiteImage from 'images/external-link-logo.svg';

function blockUser(blockedUserId) {
  const body = {
    user_block: {
      blocked_id: blockedUserId,
    },
  };

  getCsrfToken().then(sendFetch('block-user', JSON.stringify(body)));
}

const setUpButton = ({ modalId = '', otherModalId = '', btnName = '' }) => {
  return (
    <button
      type="button"
      onClick={() => {
        const modal = document.getElementById(`${modalId}`);
        const otherModal = document.getElementById(`${otherModalId}`);
        otherModal.style.display = 'none';
        if (modal.style.display === 'none') {
          modal.style.display = 'block';
          window.location.href = `#${modalId}`;
        } else {
          modal.style.display = 'none';
          window.location.href = `#`;
        }
      }}
    >
      {btnName}
    </button>
  );
};

setUpButton.propTypes = {
  modalId: PropTypes.string.isRequired,
  otherModalId: PropTypes.string.isRequired,
  btnName: PropTypes.string.isRequired,
};

const userDetailsConfig = {
  twitter_username: {
    hostUrl: 'https://twitter.com/',
    srcImage: twitterImage,
    imageAltText: 'twitter logo',
  },
  github_username: {
    hostUrl: 'https://github.com/',
    srcImage: githubImage,
    imageAltText: 'github logo',
  },
  website_url: {
    className: 'external-link-img',
    hostUrl: '',
    srcImage: websiteImage,
    imageAltText: 'external link icon',
  },
};

const UserDetails = ({ user, activeChannelId, activeChannel }) => {
  const channelId = activeChannelId;
  const channel = activeChannel || {};
  const socialIcons = [];
  const userMeta = ['twitter_username', 'github_username', 'website_url'];
  userMeta.forEach(metaProp => {
    if (user[metaProp]) {
      const { className, hostUrl, srcImage, imageAltText } = userDetailsConfig[
        metaProp
      ];
      socialIcons.push(
        <a
          href={`${hostUrl}${user[metaProp]}`}
          target="_blank"
          rel="noopener noreferrer"
        >
          <img
            className={className}
            src={srcImage}
            style={{ width: '30px', margin: '5px 15px 15px 0px' }}
            alt={imageAltText}
          />
        </a>,
      );
    }
  });
  let userLocation = '';
  if (user.location && user.location.length > 0) {
    userLocation = (
      <div>
        <div className="key">location</div>
        <div className="value">{user.location}</div>
      </div>
    );
  }
  let blockButton = '';
  if (channel.channel_type === 'direct' && window.currentUser.id !== user.id) {
    blockButton = setUpButton({
      modalId: 'userdetails__blockmsg',
      otherModalId: 'userdetails__reportabuse',
      btnName: 'Block User',
    });
  }

  let reportButton = '';
  if (window.currentUser.id !== user.id) {
    reportButton = setUpButton({
      modalId: 'userdetails__reportabuse',
      otherModalId: 'userdetails__blockmsg',
      btnName: 'Report Abuse',
    });
  }

  return (
    <div>
      <img
        src={user.profile_image}
        alt={`${user.username} profile`}
        style={{
          height: '210px',
          width: '210px',
          margin: ' 15px auto',
          display: 'block',
          borderRadius: '500px',
        }}
      />
      <h1 style={{ textAlign: 'center' }}>
        <a href={`/${user.username}`} target="_blank" rel="noopener noreferrer">
          {user.name}
        </a>
      </h1>
      <div style={{ height: '50px', margin: 'auto', width: '96%' }}>
        {socialIcons}
      </div>
      <div style={{ fontStyle: 'italic' }}>{user.summary}</div>
      <div className="activechatchannel__activecontentuserdetails">
        {userLocation}
        <div className="key">joined</div>
        <div className="value">{user.joined_at}</div>
      </div>
      <div className="userdetails__blockreport">
        {blockButton}
        {reportButton}
      </div>
      <div id="userdetails__reportabuse" style={{ display: 'none' }}>
        <div className="userdetails__reportabuse">
          <p>Reporting abuse will: </p>
          <ul>
            <li>
              close this chat and prevent this user from re-opening chat with
              you
            </li>
            <li>
              give the DEV team your consent to read messages in this chat to
              understand your report and take appropriate action
            </li>
          </ul>
          <p>
            Blocking is only on Connect right now and has not been implemented
            across DEV yet.
          </p>
          <h5>Are you sure?</h5>
          <a
            tabIndex="0"
            href="/report-abuse"
            onClick={() => {
              blockUser(channelId);
            }}
          >
            Yes, Report
          </a>
          {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
          <a
            role="button"
            tabIndex="0"
            className="no"
            onClick={() => {
              document.getElementById(
                'userdetails__reportabuse',
              ).style.display = 'none';
              window.location.href = `#`;
            }}
            onKeyUp={e => {
              if (e.keyCode === 13) {
                document.getElementById(
                  'userdetails__reportabuse',
                ).style.display = 'none';
                window.location.href = `#`;
              }
            }}
          >
            No
          </a>
        </div>
      </div>
      <div id="userdetails__blockmsg" style={{ display: 'none' }}>
        <div className="userdetails__blockmsg">
          <p>Blocking on connect will: </p>
          <ul>
            <li>
              close this chat and prevent this user from re-opening chat with
              you
            </li>
            <li>
              NOT notify the user you will block--this channel will become
              inaccessible for both users
            </li>
          </ul>
          <p>
            Blocking is only on Connect right now and has not been implemented
            across DEV yet. Consider reporting abuse to the DEV team if this
            user is spamming or harassing elsewhere on dev.to, so we can take
            further action.
          </p>
          <h5>Are you sure?</h5>
          {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
          <a
            role="button"
            tabIndex="0"
            onClick={() => {
              blockUser(user.id);
              window.location.href = `/connect`;
            }}
            onKeyUp={e => {
              if (e.keyCode === 13) {
                blockUser(user.id);
                window.location.href = `/connect`;
              }
            }}
          >
            Yes, Block
          </a>
          {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
          <a
            role="button"
            tabIndex="0"
            className="no"
            onClick={() => {
              document.getElementById('userdetails__blockmsg').style.display =
                'none';
              window.location.href = `#`;
            }}
            onKeyUp={e => {
              if (e.keyCode === 13) {
                document.getElementById('userdetails__blockmsg').style.display =
                  'none';
                window.location.href = `#`;
              }
            }}
          >
            No
          </a>
        </div>
      </div>
    </div>
  );
};

UserDetails.propTypes = {
  user: PropTypes.objectOf().isRequired,
  activeChannelId: PropTypes.string.isRequired,
  activeChannel: PropTypes.objectOf().isRequired,
};

export default UserDetails;
