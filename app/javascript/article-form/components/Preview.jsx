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
    tags = tagArray.map((tag) => {
      return (
        <span class="crayons-tag">{tag.length > 0 ? tag : ''}</span>
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
    <header className="crayons-article__header">
      {coverImageHTML}
      <h1 className="fs-4xl l:fs-5xl fw-bold s:fw-heavy lh-tight mb-6">
        {previewTitle}
      </h1>
      <div className="crayons-article__tags">{tags}</div>
    </header>
  );
}

const previewResponsePropTypes = PropTypes.shape({
  processed_html: PropTypes.string.isRequired,
  title: PropTypes.string,
  tags: PropTypes.array,
  cover_image: PropTypes.string,
});

export const Preview = ({ previewResponse, version, articleState }) => {
  return (
    <div className="crayons-card crayons-layout__content">
      <article className="crayons-article">
        {titleArea(previewResponse, version, articleState)}
        <div
          className="crayons-article__body"
          // eslint-disable-next-line react/no-danger
          dangerouslySetInnerHTML={{ __html: previewResponse.processed_html }}
        />
      </article>
    </div>
  );

}

Preview.propTypes = {
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

Preview.displayName = 'Preview';
