import { h } from 'preact';
import PropTypes from 'prop-types';

const BodyPreview = ({ previewResponse, version, articleState }) => (
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
    {titleArea(version, articleState, previewResponse)}
    <div
      className="body"
      dangerouslySetInnerHTML={{ __html: previewResponse.processed_html }}
      style={{ width: '90%' }}
    />
  </div>
);

function titleArea(version, articleState, previewResponse) {
  if (version === 'help') {
    // possibly something different here in future.
    return '';
  }
  const tagArray = previewResponse.tags || articleState.tagList.split(', ');
  let tags = ''
  if (tagArray.length > 0 && tagArray[0].length > 0) {
    tags = tagArray.map(tag => {
      return (
        <span>
          {tag.length > 0 ? <div className="tag">{tag}</div> : ''}
          {' '}
        </span>
      );
    });  
  }
  let coverImage = ''
  if (previewResponse.cover_image && previewResponse.cover_image.length > 0) {
    coverImage = <div className='articleform__mainimage articleform__mainimagepreview'><img src={previewResponse.cover_image} alt='cover image' /></div>
  } else if (articleState.mainImage) {
    coverImage = <div className='articleform__mainimage articleform__mainimagepreview'><img src={articleState.mainImage} alt='cover image' /></div>
  }
  const previewTitle = previewResponse.title || articleState.title || '';
  return (
    <div>
      {coverImage}
      <div className="title" style={{ width: '90%', maxWidth: '1000px' }}>
        <h1 className={previewTitle.length > 44 ? 'articleform_titlepreviewsmall' : '' }>{previewTitle}</h1>
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
    </div>
  );
}

BodyPreview.propTypes = {
  previewResponse: PropTypes.object.isRequired,
  articleState: PropTypes.object.isRequired,
  version: PropTypes.string.isRequired,
};

export default BodyPreview;
