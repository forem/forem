import { h } from 'preact';
import PropTypes from 'prop-types';

export const LoadingArticle = ({ version }) => {
  const bigPicArea = version === 'featured' ? <div className="picture" /> : '';
  const smallPic =
    version === 'featured' ? (
      ''
    ) : (
      <div className="small-pic">
        <div className="color single-article-loading" />
      </div>
    );
  return (
    <div
      className="single-article single-article-small-pic big-article"
      style={{ paddingBottom: version === 'featured' ? '46px' : '0' }}
    >
      {bigPicArea}
      {smallPic}
      <div className="content">
        <h3 className="single-article-loading">&nbsp;</h3>
      </div>
      <h4 className="single-article-loading" style={{ width: '46%' }}>
        &nbsp;
      </h4>
      <div className="tags single-article-loading" />
    </div>
  );
};
LoadingArticle.propTypes = {
  version: PropTypes.string.isRequired,
};
