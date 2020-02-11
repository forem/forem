import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import faker from 'faker';
import { PodcastArticle } from '..';
import { defaultChildrenPropTypes } from '../../src/components/common-prop-types/default-children-prop-types';
import '../../../assets/stylesheets/articles.scss';

const title = faker.random.words(2);

const article = {
  id: 1,
  title,
  type_of: 'podcast_episodes',
  path: '/some-post/path',
  podcast: {
    slug: title.replace(/\s+/, '-').toLowerCase(),
    title: faker.random.words(2),
    image_url: '/images/undraw_podcast_q6p7.svg',
  },
};

const ArticleWrapper = ({ children }) => (
  <div className="articles-list">{children}</div>
);
ArticleWrapper.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
};
ArticleWrapper.displayName = 'ArticleWrapper';

storiesOf('Components/Articles/Podcast Article', module).add('Default', () => (
  <ArticleWrapper>
    <PodcastArticle article={article} />
  </ArticleWrapper>
));
