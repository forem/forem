import { h } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../src/components/common-prop-types/article-prop-types';
import {
  ArticleCoverImage,
  CommentsCount,
  ContentTitle,
  Meta,
  SaveButton,
  SearchSnippet,
  TagList,
  ReactionsCount,
  Video,
} from './components';
import { PodcastArticle } from './PodcastArticle';

export const Article = ({
  article,
  isFeatured,
  isBookmarked,
  bookmarkClick,
}) => {
  if (article && article.type_of === 'podcast_episodes') {
    return <PodcastArticle article={article} />;
  }

  return (
    <div
      className={`crayons-story ${isFeatured && 'crayons-story--featured'}`}
      id={isFeatured && 'featured-story-marker'}
      data-featured-article="TODO"
      data-content-user-id={article.user_id}
    >
      {article.cloudinary_video_url && <Video article={article} />}

      {isFeatured && <ArticleCoverImage article={article} />}
      <div className="crayons-story__body">
        <div className="crayons-story__top">
          <Meta article={article} organization={article.organization} />
        </div>

        <div className="crayons-story__indention">
          <ContentTitle article={article} />
          <TagList tags={article.tag_list} />

          {article.class_name === 'Article' && (
            // eslint-disable-next-line no-underscore-dangle
            <SearchSnippet snippetResult={article._snippetResult} />
          )}

          <div className="crayons-story__bottom">
            {article.class_name !== 'User' && (
              <div className="crayons-story__details">
                <ReactionsCount article={article} />
                <CommentsCount
                  count={article.comments_count}
                  articlePath={article.path}
                />
              </div>
            )}

            <SaveButton
              article={article}
              isBookmarked={isBookmarked}
              onClick={bookmarkClick}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

Article.defaultProps = {
  isBookmarked: false,
  isFeatured: false,
};

Article.propTypes = {
  article: articlePropTypes.isRequired,
  isBookmarked: PropTypes.bool,
  isFeatured: PropTypes.bool,
  bookmarkClick: PropTypes.func.isRequired,
};
