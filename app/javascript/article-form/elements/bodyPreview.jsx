import { h } from 'preact';
import PropTypes from 'prop-types';

const CoverImage = ({ className, imageSrc, imageAlt }) => (
  <div className={className}>
    <img src={imageSrc} alt={imageAlt} />
  </div>
);

CoverImage.propTypes = {
  className: PropTypes.string.isRequired,
  imageSrc: PropTypes.string.isRequired,
  imageAlt: PropTypes.string.isRequired,
};

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
        <span>{tag.length > 0 ? <div className="tag">{tag}</div> : ''}</span>
      );
    });
  }

  // The v2 editor stores its cover image in articleState.mainImage, while the v1 editor
  // stores it as previewRespose.cover_image. When previewing, we handle both by
  // defaulting to setting the cover image to the mainImage on the article (v2),
  //  and only using the cover image from the previewResponse if it exists (v1).
  let coverImage = articleState.mainImage || '';
  if (articleState.previewShowing) {
    // In preview state, use the cover_image from previewResponse.
    if (previewResponse.cover_image && previewResponse.cover_image.length > 0) {
      coverImage = previewResponse.cover_image;
    }
  }

  const previewTitle = previewResponse.title || articleState.title || '';

  let coverImageHTML = '';
  if (coverImage.length > 0) {
    coverImageHTML = (
      <CoverImage
        className="articleform__mainimage articleform__mainimagepreview"
        imageSrc={coverImage}
        imageAlt="cover"
      />
    );
  }

  return (
    <div>
      {coverImageHTML}
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
      // eslint-disable-next-line react/no-danger
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
