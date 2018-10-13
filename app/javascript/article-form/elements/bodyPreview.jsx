import { h } from 'preact';
import PropTypes from 'prop-types';

const BodyPreview = ({ previewHTML, version, articleState }) => (
  <div
    className="container"
    style={{
      marginTop: '10px',
      minHeight: '508px',
      overflow: 'hidden',
      boxShadow: '0px 0px 0px #fff',
      border: '0px',
    }}
  >
    {titleArea(version, articleState)}
    <div
      className="body"
      dangerouslySetInnerHTML={{ __html: previewHTML }}
      style={{ width: '90%' }}
    />
  </div>
);

function titleArea(version, articleState) {
  if (version === 'help') {
    // possibly something different here in future.
    return '';
  }
  const tags = articleState.tagList.split(', ').map(tag => (
    <span>
      <div className="tag">{tag}</div>
      {' '}
    </span>
  ));
  return (
    <div className="title" style={{ width: '90%', maxWidth: '1000px' }}>
      <h1>{articleState.title}</h1>
      <h3>
        <img
          className="profile-pic"
          src={window.currentUser.profile_image_90}
          alt="image"
        />
        &nbsp;
        <span>{window.currentUser.name}</span>
      </h3>
      <div className="tags">{tags}</div>
    </div>
  );
}

BodyPreview.propTypes = {
  previewHTML: PropTypes.string.isRequired,
  version: PropTypes.string.isRequired,
};

export default BodyPreview;
