import { h } from 'preact';
import { LoadingArticle } from '..';
import '../../../assets/stylesheets/articles.scss';
import { articleDecorator } from './articleDecorator';

storiesOf('App Components/Article', module)
  .addDecorator(articleDecorator)
  .add('Article Loading', () => <LoadingArticle />);
