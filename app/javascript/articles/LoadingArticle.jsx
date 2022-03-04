import { h } from 'preact';
import PropTypes from 'prop-types';

export const LoadingArticle = ({ version }) => {
  const cover = version === 'featured' && (
    <div className="crayons-story__cover">
      <div
        className="crayons-scaffold crayons-story__cover__image"
        loading="lazy"
      />
    </div>
  );
  return (
    <div className="crayons-story" title="Loading posts...">
      {cover}
      <div className="crayons-story__body">
        <div className="crayons-story__top mb-3">
          <div className="crayons-story__meta w-100">
            <div className="crayons-scaffold-loading mr-2 w-0 h-0 p-4 radius-full" />
            <div className="crayons-scaffold-loading w-25 h-0 py-2" />
          </div>
        </div>
        <div className="crayons-story__indention">
          <div className="crayons-scaffold-loading w-75 h-0 py-3 mb-2" />
          <div className="crayons-scaffold-loading w-50 h-0 py-2 mb-8" />
        </div>
      </div>
    </div>
  );
};
LoadingArticle.propTypes = {
  version: PropTypes.string,
};
