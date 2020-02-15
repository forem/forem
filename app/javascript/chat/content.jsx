import { h, Component } from 'preact';
import PropTypes from 'prop-types';
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

function display(props) {
  if (props.resource.type_of === 'loading-user') {
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
  if (props.resource.type_of === 'article') {
    return <Article resource={props.resource} />;
  }
}
