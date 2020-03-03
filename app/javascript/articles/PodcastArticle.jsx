import { h } from 'preact';
import { articlePropTypes } from '../src/components/common-prop-types/article-prop-types';

export const PodcastArticle = ({ article }) => {
  return (
    <div className="single-article single-article-small-pic single-article-single-podcast">
      <div className="small-pic">
        <a href={`/${article.podcast.slug}`} className="small-pic-link-wrapper">
          <img src={article.podcast.image_url} alt={article.podcast.title} />
        </a>
      </div>
      <a
        href={article.path}
        className="small-pic-link-wrapper index-article-link"
        id={`article-link-${article.id}`}
      >
        <div className="content">
          <h3>
            <span className="tag-identifier">podcast</span>
            {article.title}
          </h3>
        </div>
      </a>
      <h4>
        <a href={`/${article.podcast.slug}`}>{article.podcast.title}</a>
      </h4>
    </div>
  );
};

// TODO: Move these out into common-prop-types
PodcastArticle.propTypes = {
  article: articlePropTypes.isRequired,
};
