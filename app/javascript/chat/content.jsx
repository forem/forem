import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import Article from './article';


export default class Content extends Component {
  static propTypes = {
    resource: PropTypes.object,
    activeChannelId: PropTypes.number,
    pusherKey: PropTypes.string,
    fullscreen: PropTypes.bool,
  };

  render() {
    if (!this.props.resource) {
      return '';
    }
    const fullScreenIcon = this.props.fullscreen ? <svg data-content="fullscreen" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24"><path data-content="fullscreen" fill="none" d="M0 0h24v24H0z"/><path data-content="fullscreen" d="M18 7h4v2h-6V3h2v4zM8 9H2V7h4V3h2v6zm10 8v4h-2v-6h6v2h-4zM8 15v6H6v-4H2v-2h6z"/></svg> : <svg data-content="fullscreen" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24"><path data-content="fullscreen" fill="none" d="M0 0h24v24H0z"/><path data-content="fullscreen" d="M20 3h2v6h-2V5h-4V3h4zM4 3h4v2H4v4H2V3h2zm16 16v-4h2v6h-6v-2h4zM4 19h4v2H2v-6h2v4z"/></svg>;
    return (
      <div
        className="activechatchannel__activecontent activechatchannel__activecontent--sidecar"
        id="chat_activecontent"
        onClick={this.props.onTriggerContent}
      >
        <button
          className="activechatchannel__activecontentexitbutton crayons-btn crayons-btn--secondary"
          data-content="exit"
        >
          <svg data-content="exit" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24"><path data-content="exit" fill="none" d="M0 0h24v24H0z"/><path data-content="exit" d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636z"/></svg>
        </button>
        <button
          className="activechatchannel__activecontentexitbutton activechatchannel__activecontentexitbutton--fullscreen crayons-btn crayons-btn--secondary"
          data-content="fullscreen"
          style={{left: "39px"}}
        >
          {fullScreenIcon}
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
