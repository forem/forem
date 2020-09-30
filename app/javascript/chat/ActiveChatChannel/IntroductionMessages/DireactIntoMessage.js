import { h } from 'preact';
import PropTypes from 'prop-types';

const DireactIntroMessages = ({ activeChannel }) => {
  return (
    <div className="chatmessage" style={{ color: 'grey' }}>
      <div className="chatmessage__body">
        You and{' '}
        <a href={`/${activeChannel.channel_modified_slug}`}>
          {activeChannel.channel_modified_slug}
        </a>{' '}
        are connected because you both follow each other. All interactions{' '}
        <em>
          <b>must</b>
        </em>{' '}
        abide by the <a href="/code-of-conduct">code of conduct</a>.
      </div>
    </div>
  );
};

DireactIntroMessages.propTypes = {
  activeChannel: PropTypes.object,
};

export default DireactIntroMessages;
