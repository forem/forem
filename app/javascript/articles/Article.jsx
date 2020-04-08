import { h } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../src/components/common-prop-types/article-prop-types';
import {
  CommentsCount,
  CommentsList,
  Cover,
  ContentTitle,
  Author,
  OverflowNavigation,
  SaveButton,
  SearchSnippet,
  TagList,
  ReactionsCount,
} from './components';
import { PodcastArticle } from './PodcastArticle';

export const Article = ({
  article,
  currentTag,
  isFeatured,
  isBookmarked,
  // videoIcon,
  bookmarkClick,
}) => {
  if (article && article.type_of === 'podcast_episodes') {
    return <PodcastArticle article={article} />;
  }

  return (
    <div
      className={`crayons-story ${isFeatured && ("crayons-story--featured")}`}
      id={isFeatured && ("featured-story-marker")}
      data-featured-article="TODO"
      data-content-user-id={article.user_id}
    >
      {isFeatured && (
        <Cover article={article} />
      )}
      <div className="crayons-story__body">
        <div className="crayons-story__top">
          <Author article={article} organization={article.organization} />
          <OverflowNavigation />
        </div>

        <div className="crayons-story__indention">
          <ContentTitle article={article} />
          <TagList tags={article.tag_list} />

          {article.class_name === 'Article' && (
            // eslint-disable-next-line no-underscore-dangle
            <SearchSnippet highlightText={article.highlight} />
          )}

          <div className="crayons-story__bottom">
            <div className="crayons-story__details">
              {article.class_name !== 'User' && (
                <ReactionsCount article={article} />
              )}
              {article.class_name !== 'User' && (
                <CommentsCount
                  count={article.comments_count}
                  articlePath={article.path}
                />
              )}
            </div>

            <SaveButton
              article={article}
              isBookmarked={isBookmarked}
              onClick={bookmarkClick}
            />
          </div>
        </div>
      </div>

      {/* <CommentsList /> */}
    </div>
  );
};

Article.defaultProps = {
  currentTag: null,
  isBookmarked: false,
  isFeatured: false,
};

Article.propTypes = {
  article: articlePropTypes.isRequired,
  currentTag: PropTypes.string,
  isBookmarked: PropTypes.bool,
  isFeatured: PropTypes.bool,
  videoIcon: PropTypes.string.isRequired,
  bookmarkClick: PropTypes.func.isRequired,
};
