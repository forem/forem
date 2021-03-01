import { h } from 'preact';
import PropTypes from 'prop-types';
import { useEffect } from 'preact/hooks';
import { ErrorList } from './ErrorList';

function titleArea(previewResponse, articleState, errors) {
  const tagArray = previewResponse.tags || articleState.tagList.split(', ');
  let tags = '';
  if (tagArray.length > 0 && tagArray[0].length > 0) {
    tags = tagArray.map((tag) => {
      return (
        tag.length > 0 && (
          <span className="crayons-tag mr-2">
            <span className="crayons-tag__prefix">#</span>
            {tag}
          </span>
        )
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

  return (
    <header className="crayons-article__header">
      {coverImage.length > 0 && (
        <div
          data-testid="article-form__cover"
          className="crayons-article__cover"
        >
          <img
            className="crayons-article__cover__image"
            src={coverImage}
            width="1000"
            height="420"
            alt="Post preview cover"
          />
        </div>
      )}
      <div className="crayons-article__header__meta">
        {errors && <ErrorList errors={errors} />}
        <h1 className="fs-4xl l:fs-5xl fw-bold s:fw-heavy lh-tight mb-6 spec-article__title">
          {previewTitle}
        </h1>

        <div className="spec-article__tags">{tags}</div>
      </div>
    </header>
  );
}

const previewResponsePropTypes = PropTypes.shape({
  processed_html: PropTypes.string.isRequired,
  title: PropTypes.string,
  tags: PropTypes.array,
  cover_image: PropTypes.string,
});

export const Preview = ({ previewResponse, articleState, errors }) => {
  useEffect(() => {
    if (previewResponse.processed_html.includes('twitter-timeline')) {
      attachTwitterTimelineScript();
    }
  }, [previewResponse]);

  return (
    <div className="crayons-article-form__content crayons-card">
      <article className="crayons-article">
        {titleArea(previewResponse, articleState, errors)}
        <div className="crayons-article__main">
          <div
            className="crayons-article__body text-styles"
            // eslint-disable-next-line react/no-danger
            dangerouslySetInnerHTML={{ __html: previewResponse.processed_html }}
          />
        </div>
      </article>
    </div>
  );
};

function attachTwitterTimelineScript() {
  const script = document.createElement('script');
  script.src = 'https://platform.twitter.com/widgets.js';
  script.async = true;
  document.body.appendChild(script);
  return () => {
    document.body.removeChild(script);
  };
}

Preview.propTypes = {
  previewResponse: previewResponsePropTypes.isRequired,
  errors: PropTypes.string.isRequired,
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
