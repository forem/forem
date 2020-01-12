import { h } from 'preact';
import PropTypes from 'prop-types';
import CodeEditor from './codeEditor';
import GithubRepo from './githubRepo';
import ChannelDetails from './channelDetails';
import UserDetails from './userDetails';
import Article from './article';

// eslint-disable-next-line consistent-return
function display({
  resource,
  activeChannelId,
  activeChannel,
  pusherKey,
  githubToken,
}) {
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
  if (resource.type_of === 'chat_channel') {
    return (
      <ChannelDetails channel={resource} activeChannelId={activeChannelId} />
    );
  }
  if (resource.type_of === 'code_editor') {
    return (
      <CodeEditor activeChannelId={activeChannelId} pusherKey={pusherKey} />
    );
  }
}

const Content = props => {
  const { resource, onTriggerContent } = props;
  if (resource) {
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
      {display(props)}
    </div>
  );
};

Content.propTypes = {
  resource: PropTypes.objectOf().isRequired,
  onTriggerContent: PropTypes.func.isRequired,
};
