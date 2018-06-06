import { h } from 'preact';
import { storiesOf } from '@storybook/react';
import { action } from '@storybook/addon-actions';
import faker from 'faker';
import { globalModalDecorator } from './story-decorators';
import OnboardingArticles from '../OnboardingArticles';

const getArticles = (numberOfArticles = 5) =>
  new Array(numberOfArticles).fill('').map(() => ({
    user: {
      id: faker.internet.userName(),
      name: faker.name.firstName(),
      profile_image_url: './images/storm-trooper-33x33.png',
    },
    description: faker.random.words(5),
    title: faker.random.words(2),
    positive_reactions_count: faker.random.number(),
    comments_count: faker.random.number(),
  }));
const unsavedArticles = getArticles();
const commonProps = {
  articles: unsavedArticles,
  savedArticles: unsavedArticles.slice(),
  handleSaveArticle: action('Handling save article'),
  handleSaveAllArticles: action('Saving all articles'),
};

storiesOf('Onboarding/OnboardingArticles', module)
  .addDecorator(globalModalDecorator)
  .add('All articles saved', () => <OnboardingArticles {...commonProps} />)
  .add('Some unsaved articles', () => {
    const { articles } = commonProps;
    const savedArticles = articles.slice(0, 1).concat(articles.slice(3));

    return (
      <OnboardingArticles {...commonProps} savedArticles={savedArticles} />
    );
  })
  .add('20 articles articles', () => {
    const articles = getArticles(20);
    const savedArticles = articles.slice(0, 5).concat(articles.slice(10, 13));

    return (
      <OnboardingArticles
        {...commonProps}
        articles={articles}
        savedArticles={savedArticles}
      />
    );
  })
  .add('100 articles', () => {
    const articles = getArticles(100);
    const savedArticles = articles.slice(0, 5).concat(articles.slice(10, 13));

    return (
      <OnboardingArticles
        {...commonProps}
        articles={articles}
        savedArticles={savedArticles}
      />
    );
  })
  .add('500 articles', () => {
    const articles = getArticles(500);
    const savedArticles = articles.slice(0, 5).concat(articles.slice(10, 13));

    return (
      <OnboardingArticles
        {...commonProps}
        articles={articles}
        savedArticles={savedArticles}
      />
    );
  })
  .add('1000 articles', () => {
    const articles = getArticles(1000);
    const savedArticles = articles.slice(0, 5).concat(articles.slice(10, 13));

    return (
      <OnboardingArticles
        {...commonProps}
        articles={articles}
        savedArticles={savedArticles}
      />
    );
  });
