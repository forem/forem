import { h } from 'preact';
import PropTypes from 'prop-types';

const SlideContent = ({
  imageSource,
  imageAlt,
  content,
  style = { textAlign: 'center' },
}) => (
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
        <em>Let&apos;s get started...</em>
      </strong>
    </p>
  </div>
);

SlideContent.propTypes = {
  imageSource: PropTypes.string.isRequired,
  imageAlt: PropTypes.string.isRequired,
  content: PropTypes.string.isRequired,
  style: PropTypes.shape().isRequired, // bypassing shape validator to allow for additional attributes
};

export default SlideContent;
