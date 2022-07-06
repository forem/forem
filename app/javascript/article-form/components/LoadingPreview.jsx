import { h } from 'preact';
import PropTypes from 'prop-types';

export const LoadingPreview = ({ version }) => {
  const cover = version === 'cover' && (
    <div
      className="crayons-preview__cover"
      data-testid="loading-preview__cover"
    >
      <div className="crayons-scaffold" loading="lazy" />
    </div>
  );
  return (
    <div data-testid="loading-preview" title="Loading preview...">
      {cover}
      <div className="crayons-story__indention w-100 mt-6 ">
        <div className="crayons-scaffold-loading w-50 h-0 py-4 mb-2" />
        <div className="crayons-story__meta w-100 mb-5">
          <div className="crayons-scaffold-loading w-10 h-0 py-3 mr-2" />
          <div className="crayons-scaffold-loading w-15 h-0 py-3" />
        </div>
        <div className="crayons-scaffold-loading w-80 h-0 py-3 mb-2" />
        <div className="crayons-scaffold-loading w-60 h-0 py-3 mb-2" />
        <div className="crayons-scaffold-loading w-70 h-0 py-3 mb-2" />
      </div>
    </div>
  );
};

LoadingPreview.propTypes = {
  version: PropTypes.oneOf(['default', 'cover']),
};
