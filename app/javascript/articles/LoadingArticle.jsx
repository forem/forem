import { h } from 'preact';

export const LoadingArticle = () => (
  <div className="single-article single-article-small-pic">
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
);
