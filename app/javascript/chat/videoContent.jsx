import { h, Component } from 'preact';

export default class VideoContent extends Component {

  render() {
    if (!this.props.videoPath) {
      return ""
    }
    return (
      <div
        className="activechatchannel__activecontent activechatchannel__activecontent--video"
        id="chat_activecontent_video"
      >
        <button
          className="activechatchannel__activecontentexitbutton"
          data-content="exit"
          onClick={this.props.onExit}
        >
          ×
        </button>
        <iframe src={this.props.videoPath} />
      </div>
    );
  }
}
