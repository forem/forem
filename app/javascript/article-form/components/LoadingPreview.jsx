import { h } from 'preact';
import PropTypes from 'prop-types';

export const LoadingPreview = ({ version }) => {
  const cover = version === 'cover' && (
    <div className="crayons-story__cover" data-testid="loading-preview__cover">
      <div
        className="crayons-scaffold crayons-story__cover__image"
        loading="lazy"
      />
    </div>
  );
  return (
    <div data-testid="loading-preview" title="Loading preview...">
      {cover}
      <div className="crayons-story__body mt-8">
        <div className="crayons-story__indention w-100">
          {/* top */}
          <div className="crayons-story__top w-50 mb-2">
            <div className="crayons-scaffold-loading w-100 h-0 py-5" />
          </div>
          {/* mid */}
          <div className="crayons-story__meta w-25 mb-5">
            <div className="crayons-scaffold-loading w-50 h-0 py-3 mr-2" />
            <div className="crayons-scaffold-loading w-50 h-0 py-3" />
          </div>
          {/* bottom */}
          <div className="crayons-scaffold-loading w-75 h-0 py-3 mb-2" />
          <div className="crayons-story__meta w-75 mb-2">
            <div className="crayons-scaffold-loading w-50 h-0 py-3" />
          </div>
          <div className="crayons-scaffold-loading w-50 h-0 py-3 mb-2" />
        </div>
      </div>
    </div>
  );
};

LoadingPreview.propTypes = {
  version: PropTypes.string,
};
