import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import { action } from '@storybook/addon-actions';
import faker from 'faker';
import GlobalModalWrapper from './GlobalModalWrapper';
import OnboardingArticle from '../OnboardingArticle';
import { defaultChildrenPropTypes } from '../common-prop-types';

const article = {
  user: {
    id: faker.internet.userName(),
    name: faker.name.firstName(),
    profile_image_url: './images/storm-trooper-33x33.png',
  },
  description: faker.random.words(5),
  title: faker.random.words(2),
  positive_reactions_count: 100,
  comments_count: 8,
};

const commonProps = {
  article,
  isSaved: false,
  onSaveArticle: action('Saving article'),
};

const ArticleWrapper = ({ children }) => (
  <div className="onboarding-user-container">
    <div className="onboarding-user-list">
      <div className="onboarding-user-list-body">{children}</div>
    </div>
  </div>
);

ArticleWrapper.propTypes = {
  // Diabling linting below because of https://github.com/yannickcr/eslint-plugin-react/issues/1389
  // eslint-disable-next-line react/no-typos
  children: defaultChildrenPropTypes.isRequired,
};

storiesOf('Onboarding/OnboardingArticle', module)
  .addDecorator(storyFn => (
    <GlobalModalWrapper>
      <ArticleWrapper>{storyFn()}</ArticleWrapper>
    </GlobalModalWrapper>
  ))
  .add('Already saved article', () => (
    <OnboardingArticle
      {...commonProps}
      onSaveArticle={action('Unsaving article')}
      isSaved
    />
  ))
  .add('Short title', () => <OnboardingArticle {...commonProps} />)
  .add('Medium length title', () => (
    <OnboardingArticle
      {...commonProps}
      article={{ ...article, title: faker.random.words(10) }}
    />
  ))
  .add('Long title', () => (
    <OnboardingArticle
      {...commonProps}
      article={{ ...article, title: faker.random.words(15) }}
    />
  ))
  .add('Short description', () => (
    <OnboardingArticle
      {...commonProps}
      article={{ ...article, description: faker.random.words(5) }}
    />
  ))
  .add('Medium length description', () => (
    <OnboardingArticle
      {...commonProps}
      article={{ ...article, description: faker.random.words(10) }}
    />
  ))
  .add('Long description', () => (
    <OnboardingArticle
      {...commonProps}
      article={{ ...article, description: faker.random.words(20) }}
    />
  ))
  .add('No reactions/comments count', () => (
    <OnboardingArticle
      {...commonProps}
      article={{
        ...article,
        positive_reactions_count: 0,
        comments_count: 0,
      }}
    />
  ))
  .add('10 reactions/comments', () => (
    <OnboardingArticle
      {...commonProps}
      article={{
        ...article,
        positive_reactions_count: 10,
        comments_count: 10,
      }}
    />
  ))
  .add('999 reactions/comments', () => (
    <OnboardingArticle
      {...commonProps}
      article={{
        ...article,
        positive_reactions_count: 999,
        comments_count: 999,
      }}
    />
  ))
  .add('9999 reactions/comments', () => (
    <OnboardingArticle
      {...commonProps}
      article={{
        ...article,
        positive_reactions_count: 9999,
        comments_count: 9999,
      }}
    />
  ))
  .add('99999 reactions/comments', () => (
    <OnboardingArticle
      {...commonProps}
      article={{
        ...article,
        positive_reactions_count: 99999,
        comments_count: 99999,
      }}
    />
  ))
  .add('999999 reactions/comments', () => (
    <OnboardingArticle
      {...commonProps}
      article={{
        ...article,
        positive_reactions_count: 999999,
        comments_count: 999999,
      }}
    />
  ));
