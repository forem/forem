import { h } from 'preact';
import PropTypes from 'prop-types';
import { articlePropTypes } from '../common-prop-types/article-prop-types';
import {
  ArticleCoverImage,
  CommentsCount,
  CommentsList,
  ContentTitle,
  Meta,
  SaveButton,
  SearchSnippet,
  TagList,
  ReactionsCount,
  ReadingTime,
  Video,
} from './components';
import { PodcastArticle } from './PodcastArticle';

const clickableClassList = [
  'crayons-story',
  'crayons-story__top',
  'crayons-story__body',
  'crayons-story__indention',
  'crayons-story__title',
  'crayons-story__tags',
  'crayons-story__bottom',
  'crayons-story__tertiary',
];

const shouldOpenInNewTab = (event) =>
  event.which > 1 || event.metaKey || event.ctrlKey;

const getFullUrl = (article) =>
  window.location.origin + article.path;

const renderContent = (article, isArticle) => (
  <>
    {article.cloudinary_video_url && <Video article={article} />}
    {article.main_image && <ArticleCoverImage article={article} />}
    <div className="crayons-story__body">
      <div className="crayons-story__top">
        <Meta article={article} organization={article.organization} />
        {pinned && (
          <div
            className="pinned color-accent-brand fw-bold"
            data-testid="pinned-article"
          >
            <svg
              aria-hidden="true"
              className="mr-2 align-text-bottom color-accent-brand"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              width="24"
              height="24"
            >
              <path d="M22.314 10.172l-1.415 1.414-.707-.707-4.242 4.242-.707 3.536-1.415 1.414-4.242-4.243-4.95 4.95-1.414-1.414 4.95-4.95-4.243-4.242 1.414-1.415L8.88 8.05l4.242-4.242-.707-.707 1.414-1.415z" />
            </svg>
            Pinned
            <span className="hidden s:inline">&nbsp;post</span>
          </div>
        )}
      </div>
      <div className="crayons-story__indention">
        <ContentTitle article={article} />
        <TagList tags={article.tag_list} flare_tag={article.flare_tag} />
        {isArticle && (
          <SearchSnippet highlightText={article.highlight} />
        )}
        <div className="crayons-story__bottom">
          {article.class_name !== 'User' && (
            <div className="crayons-story__details">
              <ReactionsCount article={article} />
              <CommentsCount
                count={article.comments_count}
                articlePath={article.path}
                articleTitle={article.title}
              />
            </div>
          )}
          <div className="crayons-story__save">
            <ReadingTime readingTime={article.reading_time} />
            <SaveButton
              article={article}
              isBookmarked={isBookmarked}
              onClick={bookmarkClick}
              saveable={saveable}
            />
          </div>
        </div>
      </div>
    </div>
  </>
);

export const Article = ({
  article,
  isFeatured,
  isBookmarked,
  bookmarkClick,
  feedStyle,
  pinned,
  saveable,
}) => {
  const isArticle = article.class_name === 'Article
