import { h } from 'preact';
import PropTypes from 'prop-types';

const BodyPreview = ({ previewHTML }) => (
  <div className="container" style={{marginTop: "10px",minHeight:"508px", overflow:"hidden"}}>
    <div className="body" dangerouslySetInnerHTML={{__html: previewHTML}} style={{width: "90%"}}>
    </div>
  </div>
);

BodyPreview.propTypes = {
  previewHTML: PropTypes.string.isRequired,
};

export default BodyPreview;





