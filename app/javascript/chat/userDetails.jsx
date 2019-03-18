import { h, Component } from 'preact';
import twitterImage from 'images/twitter-logo.svg';
import githubImage from 'images/github-logo.svg';
import websiteImage from 'images/external-link-logo.svg';

function blockChat(activeChannelId) {
  const formData = new FormData();
  formData.append('chat_id', activeChannelId);
  formData.append('controller', 'chat_channels');

  getCsrfToken()
    .then(sendFetch('block-chat', formData));
}

export default class UserDetails extends Component {
  render() {
    const { user } = this.props;
    const channelId = this.props.activeChannelId;
    const socialIcons = [];
    if (user.twitter_username) {
      socialIcons.push(
        <a
          href={`https://twitter.com/${user.twitter_username}`}
          target="_blank"
        >
          <img
            src={twitterImage}
            style={{ width: '30px', margin: '5px 15px 15px 0px' }}
          />
        </a>,
      );
    }
    if (user.github_username) {
      socialIcons.push(
        <a href={`https://github.com/${user.github_username}`} target="_blank">
          <img
            src={githubImage}
            style={{ width: '30px', margin: '5px 15px 15px 0px' }}
          />
        </a>,
      );
    }
    if (user.website_url) {
      socialIcons.push(
        <a href={user.website_url} target="_blank">
          <img
            src={websiteImage}
            style={{ width: '30px', margin: '5px 15px 15px 0px' }}
          />
        </a>,
      );
    }
    let userLocation = '';
    if (user.location && user.location.length > 0) {
      userLocation = (
        <div>
          <div className="key">location</div>
          <div className="value">{user.location}</div>
        </div>
      );
    }
    return (
      <div>
        <img
          src={user.profile_image}
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
          <button
            onClick={() => {
              blockChat(channelId);
              window.location.href = `/connect`;
            }}
          >
            Block User
          </button>

          <button onClick={() => {
            var modal = document.getElementById("userdetails__reportabuse");
            if (modal.style.display === "none") {
              modal.style.display = "block";
              window.location.href = `#userdetails__reportabuse`;

            } else {
              modal.style.display = "none";
              window.location.href = `#`;
            }
          }}>
            Report Abuse
          </button>

        </div>
        <div id="userdetails__reportabuse" style="display:none">
          <div className="userdetails__reportabuse">
            <p>Reporting abuse will: </p>
            <ul>
              <li>close this chat and prevent this user from re-opening chat with you</li>
              <li>give the DEV team your consent to read messages in this chat to understand your report</li>
            </ul>
            <h5>Are you sure?</h5>
            <a href="/report-abuse" onClick={() => {
              blockChat(channelId);
            }}>Yes</a>
            <a class="no" onClick={() => {
              document.getElementById("userdetails__reportabuse").style.display = "none";
              window.location.href = `#`;
            }}>No</a>
          </div>
        </div>
      </div>
    );
  }
}
