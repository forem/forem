/* eslint-disable jsx-a11y/iframe-has-title */
import { h, Component } from 'preact';
import PropTypes from 'prop-types';

export default class VideoContent extends Component {
  static propTypes = {
    fullscreen: PropTypes.string.isRequired,
    videoPath: PropTypes.string.isRequired,
    onTriggerVideoContent: PropTypes.func.isRequired,
  };

  render() {
    const { fullscreen, videoPath, onTriggerVideoContent } = this.props;
    if (!videoPath) {
      return '';
    }

    const smartSvgIcon = (content, d) => (
      <svg
        data-content={content}
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        width="24"
        height="24"
      >
        <path data-content={content} fill="none" d="M0 0h24v24H0z" />
        <path data-content={content} d={d} />
      </svg>
    );
    return (
      // eslint-disable-next-line jsx-a11y/click-events-have-key-events
      <div
        className="activechatchannel__activecontent activechatchannel__activecontent--video"
        id="chat_activecontent_video"
        onClick={onTriggerVideoContent}
        role="button"
        tabIndex="0"
      >
        <button
          className="activechatchannel__activecontentexitbutton crayons-btn crayons-btn--secondary"
          data-content="exit"
          type="button"
        >
          {smartSvgIcon(
            'exit',
            'M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636z',
          )}
        </button>
        <button
          className="activechatchannel__activecontentexitbutton activechatchannel__activecontentexitbutton--fullscreen crayons-btn crayons-btn--secondary"
          data-content="fullscreen"
          style={{ left: '39px' }}
          type="button"
        >
          {fullscreen
            ? smartSvgIcon(
                'fullscreen',
                'M18 7h4v2h-6V3h2v4zM8 9H2V7h4V3h2v6zm10 8v4h-2v-6h6v2h-4zM8 15v6H6v-4H2v-2h6z',
              )
            : smartSvgIcon(
                'fullscreen',
                'M20 3h2v6h-2V5h-4V3h4zM4 3h4v2H4v4H2V3h2zm16 16v-4h2v6h-6v-2h4zM4 19h4v2H2v-6h2v4z',
              )}
        </button>
        <iframe src={videoPath} />
      </div>
    );
  }
}
