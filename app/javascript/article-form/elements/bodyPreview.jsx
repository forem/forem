import { h } from 'preact';
import PropTypes from 'prop-types';

function titleArea(previewResponse, version, articleState) {
  if (version === 'help') {
    // possibly something different here in future.
    return '';
  }

  const tagArray = previewResponse.tags || articleState.tagList.split(', ');
  let tags = '';
  if (tagArray.length > 0 && tagArray[0].length > 0) {
    tags = tagArray.map(tag => {
      return (
        <span>{tag.length > 0 ? <div className="tag">{tag}</div> : ''} </span>
      );
    });
  }

  let coverImage = '';
  if (previewResponse.cover_image && previewResponse.cover_image.length > 0) {
    coverImage = (
      <div className="articleform__mainimage articleform__mainimagepreview">
        <img src={previewResponse.cover_image} alt="cover" />
      </div>
    );
  } else if (articleState.mainImage) {
    coverImage = (
      <div className="articleform__mainimage articleform__mainimagepreview">
        <img src={articleState.mainImage} alt="cover" />
      </div>
    );
  }

  const previewTitle = previewResponse.title || articleState.title || '';

  return (
    <div>
      {coverImage}
      <div className="title" style={{ width: '90%', maxWidth: '1000px' }}>
        <h1
          className={
            previewTitle.length > 44 ? 'articleform_titlepreviewsmall' : ''
          }
        >
          {previewTitle}
        </h1>
        <h3>
          <img
            className="profile-pic"
            src={window.currentUser.profile_image_90}
            alt="profile"
          />
          &nbsp;
          <span>{window.currentUser.name}</span>
        </h3>
        <div className="tags">{tags}</div>
      </div>
    </div>
  );
}

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
    {titleArea(previewResponse, version, articleState)}
    <div
      className="body"
      dangerouslySetInnerHTML={{ __html: previewResponse.processed_html }}
      style={{ width: '90%' }}
    />
  </div>
);

const previewResponsePropTypes = PropTypes.shape({
  processed_html: PropTypes.string.isRequired,
  title: PropTypes.string,
  tags: PropTypes.array,
  cover_image: PropTypes.string,
});

BodyPreview.propTypes = {
  previewResponse: previewResponsePropTypes.isRequired,
  version: PropTypes.string.isRequired,
  articleState: PropTypes.shape({
    id: PropTypes.number,
    title: PropTypes.string,
    tagList: PropTypes.string,
    description: PropTypes.string,
    canonicalUrl: PropTypes.string,
    series: PropTypes.string,
    allSeries: PropTypes.arrayOf(PropTypes.string),
    bodyMarkdown: PropTypes.string,
    published: PropTypes.bool,
    previewShowing: PropTypes.bool,
    helpShowing: PropTypes.bool,
    previewResponse: previewResponsePropTypes,
    helpHTML: PropTypes.string,
    submitting: PropTypes.bool,
    editing: PropTypes.bool,
    imageManagementShowing: PropTypes.bool,
    moreConfigShowing: PropTypes.bool,
    mainImage: PropTypes.string,
    organization: PropTypes.shape({
      name: PropTypes.string.isRequired,
      bg_color_hex: PropTypes.string.isRequired,
      text_color_hex: PropTypes.string.isRequired,
      profile_image_90: PropTypes.string.isRequired,
    }),
    postUnderOrg: PropTypes.bool,
    errors: PropTypes.any,
    edited: PropTypes.bool,
    version: PropTypes.string,
  }).isRequired,
};

export default BodyPreview;
