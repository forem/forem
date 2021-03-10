import { h } from 'preact';

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

/**
 * Displays video in Connect.
 *
 * @param {string} props.videoPath The URL of a video
 * @param {function} props.onTriggerVideoContent Fires when a video is clicked on
 * @param {boolean} props.fullscreen Whether or not to show the video in fullscreen
 *
 * @returns A video component
 */
export function VideoContent(props) {
  const { videoPath, onTriggerVideoContent, fullscreen } = props;

  if (!videoPath) {
    return null;
  }

  return (
    <div
      data-testid="connect-video"
      role="presentation"
      className="activechatchannel__activecontent activechatchannel__activecontent--video"
      id="chat_activecontent_video"
      onClick={onTriggerVideoContent}
    >
      <button
        aria-label="Exit"
        className="activechatchannel__activecontentexitbutton crayons-btn crayons-btn--secondary"
        data-content="exit"
      >
        {smartSvgIcon(
          'exit',
          'M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636z',
        )}
      </button>
      <button
        aria-label={fullscreen ? 'Fullscreen' : 'Leave fullscreen'}
        className="activechatchannel__activecontentexitbutton activechatchannel__activecontentexitbutton--fullscreen crayons-btn crayons-btn--secondary"
        data-content="fullscreen"
        style={{ left: '-80px', marginLeft:'0px' }}
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
      <iframe title="Video display" src={videoPath} />
    </div>
  );
}
