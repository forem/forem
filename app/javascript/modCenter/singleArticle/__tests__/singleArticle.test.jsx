import { h, Fragment } from 'preact';
import { axe } from 'jest-axe';
import { render, getNodeText, waitFor } from '@testing-library/preact';
import { SingleArticle } from '../index';
import '@testing-library/jest-dom';

const getTestArticle = () => ({
  id: 1,
  title: 'An article title',
  path: 'an-article-title-di3',
  publishedAt: '2019-06-22T16:11:10.590Z',
  cachedTagList: 'discuss, javascript, beginners',
  user: {
    articles_count: 1,
    name: 'hello',
  },
});

describe('<SingleArticle />', () => {
  it('should have no a11y violations', async () => {
    // TODO: The axe custom rules here should be removed when the below issue is fixed
    // https://github.com/forem/forem/issues/14100
    const customAxeRules = {
      'nested-interactive': { enabled: false },
    };

    const { container } = render(
      <Fragment>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
      </Fragment>,
    );
    const results = await axe(container, { rules: customAxeRules });
    expect(results).toHaveNoViolations();
  });

  it('renders the article title', () => {
    const articleProps = getTestArticle();
    const { getByRole } = render(
      <Fragment>
        <SingleArticle {...articleProps} toggleArticle={jest.fn()} />
      </Fragment>,
    );

    expect(
      getByRole('heading', { name: articleProps.title, level: 3 }),
    ).toBeInTheDocument();
  });

  it('renders the tags', () => {
    const { getByText } = render(
      <Fragment>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
      </Fragment>,
    );

    expect(getByText('discuss')).toBeInTheDocument();
    expect(getByText('javascript')).toBeInTheDocument();
    expect(getByText('beginners')).toBeInTheDocument();
  });

  it('renders no tags or # symbol when article has no tags', () => {
    const article = {
      id: 2,
      title:
        'An article title that is quite very actually rather extremely long with all things considered',
      path: 'an-article-title-that-is-quite-very-actually-rather-extremely-long-with-all-things-considered-fi8',
      publishedAt: '2019-06-24T09:32:10.590Z',
      cachedTagList: '',
      user: {
        articles_count: 1,
        name: 'howdy',
      },
    };
    const { container } = render(
      <Fragment>
        <SingleArticle {...article} toggleArticle={jest.fn()} />
      </Fragment>,
    );
    const text = getNodeText(
      container.getElementsByClassName('article-title')[0],
    );
    expect(text).not.toContain('#');
  });

  it('renders the author name', () => {
    const { container } = render(
      <Fragment>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
      </Fragment>,
    );
    const text = getNodeText(
      container.getElementsByClassName('article-author')[0],
    );
    expect(text).toContain(getTestArticle().user.name);
  });

  it('renders the hand wave emoji if the author has less than 3 articles', () => {
    const { container } = render(
      <Fragment>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
      </Fragment>,
    );
    const text = getNodeText(
      container.getElementsByClassName('article-author')[0],
    );
    expect(text).toContain('👋');
  });

  it('renders the correct formatted published date', () => {
    const { getByText } = render(
      <Fragment>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
      </Fragment>,
    );

    expect(getByText('Jun 22')).toBeInTheDocument();
  });

  it('renders the correct formatted published date as a time if the date is the same day', () => {
    const article = getTestArticle();
    const publishDate = new Date('Wed Jul 08 2020 12:11:27 GMT-0400');
    article.publishedAt = publishDate.toISOString();

    render(
      <Fragment>
        <SingleArticle {...article} toggleArticle={jest.fn()} />
      </Fragment>,
    );

    const readableTime = publishDate
      .toLocaleTimeString('en-US', { hour12: true })
      .replace(/:\d{2}\s/, ' '); // looks like 8:05 PM

    expect(
      document.getElementsByTagName('time')[0].getAttribute('datetime'),
    ).toEqual('2020-07-08T16:11:27.000Z');

    expect(readableTime).toEqual('4:11 PM');
  });

  it('toggles the article when clicked', () => {
    const toggleArticle = jest.fn();
    const article = getTestArticle();
    const { getByTestId } = render(
      <Fragment>
        <SingleArticle {...article} toggleArticle={toggleArticle} />
      </Fragment>,
    );

    const detailsElement = getByTestId(`mod-article-${article.id}`);
    const summarySection = detailsElement.getElementsByTagName('summary')[0];
    summarySection.click();

    waitFor(() => expect(toggleArticle).toHaveBeenCalledTimes(1));
  });
});
