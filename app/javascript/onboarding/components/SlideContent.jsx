import { h } from 'preact';
import PropTypes from 'prop-types';

const SlideContent = ({ imageSource, imageAlt, content, style = { textAlign: 'center' } }) => (
  <div style={style}>
    <img
      src={imageSource}
      alt={imageAlt}
      style={{ borderRadius: '8px', height: '220px' }}
    />
    <br />
    {content}
    <p>
      <strong>
        <em>Let's get started...</em>
      </strong>
    </p>
  </div>
);

SlideContent.propTypes = {
  imageSource: PropTypes.string,
  imageAlt: PropTypes.string,
  content: PropTypes.string,
  style: PropTypes.object,
};

export default SlideContent;
