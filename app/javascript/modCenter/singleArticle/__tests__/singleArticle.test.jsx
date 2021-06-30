/* eslint-disable jest/expect-expect */
import { h, Fragment } from 'preact';
import { axe } from 'jest-axe';
import { render, getNodeText } from '@testing-library/preact';
import { SingleArticle } from '../index';

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
        {/* Div below needed for this test to pass while preserve FlagUserModal functionality */}
        <div
          data-testid="flag-user-modal-container"
          class="flag-user-modal-container hidden"
        />
      </Fragment>,
    );
    const results = await axe(container, { rules: customAxeRules });
    expect(results).toHaveNoViolations();
  });

  it('renders the article title', () => {
    const { queryByText } = render(
      <Fragment>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
        <div
          data-testid="flag-user-modal"
          class="flag-user-modal-container hidden"
        />
      </Fragment>,
    );

    expect(queryByText(getTestArticle().title)).toBeDefined();
  });

  it('renders the new clickable article title', () => {
    const { container } = render(
      <Fragment>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
        <div
          data-testid="flag-user-modal"
          class="flag-user-modal-container hidden"
        />
      </Fragment>,
    );
    const text = getNodeText(
      container.getElementsByClassName('article-title-link')[0],
    );
    expect(text).toContain(getTestArticle().title);
  });

  it('renders the tags', () => {
    const { queryByText } = render(
      <Fragment>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
        <div
          data-testid="flag-user-modal"
          class="flag-user-modal-container hidden"
        />
      </Fragment>,
    );

    expect(queryByText('discuss')).toBeDefined();
    expect(queryByText('javascript')).toBeDefined();
    expect(queryByText('beginners')).toBeDefined();
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
        <div
          data-testid="flag-user-modal"
          class="flag-user-modal-container hidden"
        />
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
        <div
          data-testid="flag-user-modal"
          class="flag-user-modal-container hidden"
        />
      </Fragment>,
    );
    const text = getNodeText(
      container.getElementsByClassName('article-author')[0],
    );
    expect(text).toContain(getTestArticle().user.name);
  });

  it('renders the hand wave emoji if the author has less than 3 articles ', () => {
    const { container } = render(
      <Fragment>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
        <div
          data-testid="flag-user-modal"
          class="flag-user-modal-container hidden"
        />
      </Fragment>,
    );
    const text = getNodeText(
      container.getElementsByClassName('article-author')[0],
    );
    expect(text).toContain('👋');
  });

  it('renders the correct formatted published date', () => {
    const { queryByText } = render(
      <Fragment>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
        <div
          data-testid="flag-user-modal"
          class="flag-user-modal-container hidden"
        />
      </Fragment>,
    );

    expect(queryByText('Jun 22')).toBeDefined();
  });

  it('renders the correct formatted published date as a time if the date is the same day', () => {
    const article = getTestArticle();
    const publishDate = new Date('Wed Jul 08 2020 12:11:27 GMT-0400');
    article.publishedAt = publishDate.toISOString();

    render(
      <Fragment>
        <SingleArticle {...article} toggleArticle={jest.fn()} />
        <div
          data-testid="flag-user-modal"
          class="flag-user-modal-container hidden"
        />
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
        <div
          data-testid="flag-user-modal"
          class="flag-user-modal-container hidden"
        />
      </Fragment>,
    );

    const button = getByTestId(`mod-article-${article.id}`);
    button.click();

    expect(toggleArticle).toHaveBeenCalledTimes(1);
  });
});
