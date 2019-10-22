import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import CodeEditor from './codeEditor';
import GithubRepo from './githubRepo';
import ChannelDetails from './channelDetails';
import UserDetails from './userDetails';
import Article from './article';

function Display(props) {
  const {
    resource,
    activeChannelId,
    activeChannel,
    pusherKey,
    githubToken,
  } = props;
  if (resource.type_of === 'loading-user') {
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
  }
  if (resource.type_of === 'loading-user') {
    return (
      <div
        style={{
          height: '25px',
          width: '96%',
          margin: ' 8px auto',
          display: 'block',
          backgroundColor: '#f5f6f7',
        }}
      />
    );
  }
  if (resource.type_of === 'user') {
    return (
      <UserDetails
        user={resource}
        activeChannelId={activeChannelId}
        activeChannel={activeChannel}
      />
    );
  }
  if (resource.type_of === 'article') {
    return <Article resource={resource} />;
  }
  if (resource.type_of === 'github') {
    return (
      <GithubRepo
        activeChannelId={activeChannelId}
        pusherKey={pusherKey}
        githubToken={githubToken}
        resource={resource}
      />
    );
  }
  if (props.resource.type_of === 'chat_channel') {
    return (
      <ChannelDetails channel={resource} activeChannelId={activeChannelId} />
    );
  }
  if (props.resource.type_of === 'code_editor') {
    return (
      <CodeEditor activeChannelId={activeChannelId} pusherKey={pusherKey} />
    );
  }
}

Display.propTypes = {
  activeChannelId: PropTypes.string.isRequired,
  resource: PropTypes.objectOf().isRequired,
  activeChannel: PropTypes.objectOf().isRequired,
  pusherKey: PropTypes.string.isRequired,
  githubToken: PropTypes.string.isRequired,
};

export default class Content extends Component {
  static propTypes = {
    resource: PropTypes.objectOf().isRequired,
    onTriggerContent: PropTypes.func.isRequired,
  };

  render() {
    const { resource, onTriggerContent } = this.props;
    if (!resource) {
      return '';
    }
    return (
      <div
        role="presentation"
        className="activechatchannel__activecontent"
        id="chat_activecontent"
        onClick={onTriggerContent}
      >
        <button
          type="button"
          className="activechatchannel__activecontentexitbutton"
          data-content="exit"
        >
          ×
        </button>
        {Display(this.props)}
      </div>
    );
  }
}
