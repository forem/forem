import { h } from 'preact';

export const LoadingArticle = ({version}) => {
  const bigPicArea = version === 'featured' ? <div class="picture"></div> : ''
  return (
    <div className="single-article single-article-small-pic big-article">
      {bigPicArea}
      <div className="small-pic">
        <div className="color single-article-loading" />
      </div>
      <div className="content">
        <h3 className="single-article-loading">&nbsp;</h3>
      </div>
      <h4 className="single-article-loading" style={{ width: '46%' }}>
        &nbsp;
      </h4>
      <div className="tags single-article-loading" style={{ width: '56%' }} />
    </div>
  )
};
