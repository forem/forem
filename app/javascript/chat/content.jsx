import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import CodeEditor from './codeEditor';
import GithubRepo from './githubRepo';
import ChannelDetails from './channelDetails';
import UserDetails from './userDetails';
import Article from './article';

export default class Content extends Component {
  static propTypes = {
    resource: PropTypes.object,
    activeChannelId: PropTypes.number,
    pusherKey: PropTypes.string,
  };

  render() {
    if (!this.props.resource) {
      return '';
    }
    return (
      <div
        className="activechatchannel__activecontent"
        id="chat_activecontent"
        onClick={this.props.onTriggerContent}
      >
        <button
          className="activechatchannel__activecontentexitbutton"
          data-content="exit"
        >
          ×
        </button>
        {display(this.props)}
      </div>
    );
  }
}

const loadingUser = () => {
  return (
    <div
      style={{
        height: '210px',
        width: '210px',
        margin: ' 15px auto',
        display: 'block',
        borderRadius: '500px',
        backgroundColor: '#f5f6f7',
      }}
    />
  );
};

const renderUserDetails = props => {
  return (
    <UserDetails
      user={props.resource}
      activeChannelId={props.activeChannelId}
      activeChannel={props.activeChannel}
    />
  );
};

const renderArticle = props => {
  return <Article resource={props.resource} />;
};

const renderGitHubRepo = props => {
  return (
    <GithubRepo
      activeChannelId={props.activeChannelId}
      pusherKey={props.pusherKey}
      githubToken={props.githubToken}
      resource={props.resource}
    />
  );
};

const renderChannelDetails = props => {
  return (
    <ChannelDetails
      channel={props.resource}
      activeChannelId={props.activeChannelId}
    />
  );
};

const renderCodeEditor = props => {
  return (
    <CodeEditor
      activeChannelId={props.activeChannelId}
      pusherKey={props.pusherKey}
    />
  );
};

const displayMethods = {
  'loading-user': loadingUser,
  'user': renderUserDetails,
  'article': renderArticle,
  'github': renderGitHubRepo,
  'chat_channel': renderChannelDetails,
  'code_editor': renderCodeEditor,
};

const display = props => {
  const content = displayMethods[props.resource.type_of];

  if (!content) {
    return null;
  }
  return content(props);
};
