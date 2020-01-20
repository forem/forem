import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import CodeEditor from './codeEditor';
import GithubRepo from './githubRepo';
import ChannelDetails from './channelDetails';
import UserDetails from './userDetails';
import Article from './article';

const displayOptions = {
  'loading-user': () => (
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
  ),
  user: props => (
    <UserDetails
      user={props.resource}
      activeChannelId={props.activeChannelId}
      activeChannel={props.activeChannel}
    />
  ),
  article: props => <Article resource={props.resource} />,
  github: props => (
    <GithubRepo
      activeChannelId={props.activeChannelId}
      pusherKey={props.pusherKey}
      githubToken={props.githubToken}
      resource={props.resource}
    />
  ),
  chat_channel: props => (
    <ChannelDetails
      channel={props.resource}
      activeChannelId={props.activeChannelId}
    />
  ),
  code_editor: props => (
    <CodeEditor
      activeChannelId={props.activeChannelId}
      pusherKey={props.pusherKey}
    />
  ),
};

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
    const renderDisplay = displayOptions[this.props.resource.type_of];
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
        {renderDisplay(this.props)}
      </div>
    );
  }
}
