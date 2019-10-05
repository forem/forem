import { h, Component } from 'preact';
import twitterImage from 'images/twitter-logo.svg';
import githubImage from 'images/github-logo.svg';
import websiteImage from 'images/external-link-logo.svg';

function blockChat(activeChannelId) {
  const formData = new FormData();
  formData.append('chat_id', activeChannelId);
  formData.append('controller', 'chat_channels');

  getCsrfToken().then(sendFetch('block-chat', formData));
}

const setUpButton = ({ modalId = '', otherModalId = '', btnName = '' }) => {
  return (
    <button
      onClick={() => {
        const modal = document.getElementById(`${modalId}`);
        const otherModal = document.getElementById(
          `${otherModalId}`,
        );
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
}

const userDetailsConfig = {
  twitter_username: {
    hostUrl: 'https://twitter.com/',
    srcImage: twitterImage,
    imageAltText: 'twitter logo'
  },
  github_username: {
    hostUrl: 'https://github.com/',
    srcImage: githubImage,
    imageAltText: 'github logo'
  },
  website_url: {
    className: 'external-link-img',
    hostUrl: '',
    srcImage: websiteImage,
    imageAltText: 'external link icon'
  }
}

const SocialIcons = ({ user }) => {
  const userMeta = Object.keys(userDetailsConfig);
  return (
    <div style={{ height: '50px', margin: 'auto', width: '96%' }}>
      {userMeta.map(metaProp =>
        user[metaProp] ? (
          <a
            href={`${userDetailsConfig[metaProp].hostUrl}${user[metaProp]}`}
            target="_blank"
          >
            <img
              className={userDetailsConfig[metaProp].className}
              src={userDetailsConfig[metaProp].srcImage}
              style={{ width: '30px', margin: '5px 15px 15px 0px' }}
              alt={userDetailsConfig[metaProp].imageAltText}
            />
          </a>
        ) : null
      )}
    </div>
  );
};


const UserLocation = ({ location }) => 
  (location && location.length) ? (
    <div>
      <div className="key">location</div>
      <div className="value">{location}</div>
    </div>
  ) : null;

const BlockReportButtons = ({ channel, user }) => (
  <div className="userdetails__blockreport">
    {
      channel.channel_type === 'direct' && window.currentUser.id != user.id
        ? setUpButton({
            modalId: 'userdetails__blockmsg',
            otherModalId: 'userdetails__reportabuse',
            btnName: 'Block User'
          })
        : null
    }
    {
      setUpButton({
        modalId: 'userdetails__reportabuse',
        otherModalId: 'userdetails__blockmsg',
        btnName: 'Report Abuse'
      })
    }
  </div>
)

const UserDetailsModal = ({ id, children, actionText, liTexts, pText }) => (
  <div id={id} style="display:none">
    <div className={id}>
      <p>
        {actionText}
        {' '}
        will:
        {' '}
      </p>
      <ul>
        {liTexts.map(text => (
          <li>{text}</li>
        ))}
      </ul>
      <p>{pText}</p>
      <h5>Are you sure?</h5>
      {children}
      <a
        tabIndex="0"
        className="no"
        onClick={() => {
          document.getElementById(id).style.display = 'none';
          window.location.href = `#`;
        }}
        onKeyUp={e => {
          if (e.keyCode === 13) {
            document.getElementById(id).style.display = 'none';
            window.location.href = `#`;
          }
        }}
      >
        No
      </a>
    </div>
  </div>
);


const UserDetails = ({ user, activeChannelId, activeChannel }) => {
  const channelId = activeChannelId;
  const channel = activeChannel || {};
  return (
    <div>
      <img
        src={user.profile_image}
        alt={`${user.username} profile image`}
        style={{
          height: '210px',
          width: '210px',
          margin: ' 15px auto',
          display: 'block',
          borderRadius: '500px',
        }}
      />
      <h1 style={{ textAlign: 'center' }}>
        <a href={`/${user.username}`} target="_blank">
          {user.name}
        </a>
      </h1>
      <SocialIcons user={user} />
      <div style={{ fontStyle: 'italic' }}>{user.summary}</div>
      <div className="activechatchannel__activecontentuserdetails">
        <UserLocation location={user.location} />
        <div className="key">joined</div>
        <div className="value">{user.joined_at}</div>
      </div>
      <BlockReportButtons channel={channel} user={user} />  
      <UserDetailsModal
        id="userdetails__reportabuse"
        actionText="Reporting abuse"
        liTexts={[
          'close this chat and prevent this user from re-opening chat with you',
          'give the DEV team your consent to read messages in this chat to understand your report and take appropriate action'
        ]}
        pText="Blocking is only on Connect right now and has not been implemented across DEV yet."
      >
        <a
          tabIndex="0"
          href="/report-abuse"
          onClick={() => {
            blockChat(channelId);
          }}
        >
          Yes, Report
        </a>
      </UserDetailsModal>
      <UserDetailsModal
        id="userdetails__blockmsg"
        actionText="Blocking on connect"
        liTexts={[
          'close this chat and prevent this user from re-opening chat with you',
          'NOT notify the user you will block--this channel will become inaccessible for both users'
        ]}
        pText="Blocking is only on Connect right now and has not been implemented
        across DEV yet. Consider reporting abuse to the DEV team if this
        user is spamming or harassing elsewhere on dev.to, so we can take
        further action."
      >
        <a
          tabIndex="0"
          onClick={() => {
              blockChat(channelId);
              window.location.href = `/connect`;
            }}
          onKeyUp={e => {
              if (e.keyCode === 13) {
                blockChat(channelId);
                window.location.href = `/connect`;
              }
            }}
        >
            Yes, Block
        </a>
      </UserDetailsModal>
    </div>
  );
}

export default UserDetails