import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { AllListings } from '../components/AllListings';
import '../../../assets/javascripts/utilities/localDateTime';

const firstListing = {
  id: 20,
  category: 'misc',
  location: 'West Refugio',
  processed_html:
    '\u003cp\u003eEius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
  slug: 'illo-iure-quos-htyashsayas-5hk7',
  title: 'Mentor wanted',
  tags: ['go', 'git'],
  user_id: 1,
  author: {
    name: 'Evil Corp Org',
    username: 'evil_corp_org',
    profile_image_90:
      '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
  },
  user: {
    username: 'mrschristiansenyoko',
  },
};

const secondListing = {
  id: 21,
  category: 'misc',
  location: 'West Refugio',
  processed_html:
    '\u003cp\u003eEius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
  slug: 'illo-iure-quos-ereerr-5hk7',
  title: 'This is an awesome listing',
  tags: ['functional', 'clojure'],
  user_id: 1,
  author: {
    name: 'Mr. Rogers',
    username: 'fred',
    profile_image_90:
      '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
  },
  user: {
    username: 'fred',
  },
};

const thirdListing = {
  id: 22,
  category: 'misc',
  location: 'West Refugio',
  processed_html:
    '\u003cp\u003eBobby says hello. Eius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
  slug: 'illo-iure-fss-ssasas-5hk7',
  title: 'Illo iure quos perspiciatis',
  tags: ['twitter', 'learning'],
  user_id: 1,
  author: {
    name: 'Mrs. John Mack',
    username: 'mrsjohnmack',
    profile_image_90:
      '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
  },
  user: {
    username: 'mrsjohnmack',
  },
};

const listings = [firstListing, secondListing, thirdListing];

const getProps = () => ({
  listings,
  onAddTag: () => {
    return 'onAddTag';
  },
  onChangeCategory: () => {
    return 'onChangeCategory';
  },
  currentUserId: 1,
  message: 'Something',
  onOpenModal: () => {
    return 'onSubmit;';
  },
});

const renderAllListings = () => render(<AllListings {...getProps()} />);

/* eslint-disable no-unused-vars */
/* global globalThis timestampToLocalDateTimeLong timestampToLocalDateTimeShort */

describe('<AllListings />', () => {
  afterAll(() => {
    delete globalThis.timestampToLocalDateTimeLong;
    delete globalThis.timestampToLocalDateTimeShort;
  });

  it('should have no a11y violations', async () => {
    const { container } = renderAllListings();
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render the given listings', async () => {
    const { getByTestId, getByText, getByRole } = renderAllListings();

    // 1st listings
    getByTestId('single-listing-20');

    // listing title
    const listing1Title = getByRole('link', { name: 'Mentor wanted' });

    expect(listing1Title.getAttribute('href')).toEqual(
      '/listings/misc/illo-iure-quos-htyashsayas-5hk7',
    );

    // listing body
    getByText(/Eius et ullam. Dolores et qui. Quis/, {
      selector: '[data-testid="single-listing-20"] *',
    });

    // listing tags
    const goTag = getByText('go', {
      selector: '[data-testid="single-listing-20"] a',
    });

    expect(goTag.getAttribute('href')).toEqual('/listings?t=go');

    const gitTag = getByText('git', {
      selector: '[data-testid="single-listing-20"] a',
    });

    expect(gitTag.getAttribute('href')).toEqual('/listings?t=git');

    // listing author
    const listing1Author = getByText('Evil Corp Org', {
      selector: '[data-testid="single-listing-20"] a',
    });

    expect(listing1Author.getAttribute('href')).toEqual('/evil_corp_org');

    // 2nd listing
    getByTestId('single-listing-21');

    // listing title
    const listing2Title = getByRole('link', {
      name: 'This is an awesome listing',
    });

    expect(listing2Title.getAttribute('href')).toEqual(
      '/listings/misc/illo-iure-quos-ereerr-5hk7',
    );

    // listing body
    getByText(/Eius et ullam. Dolores et qui. Quis/, {
      selector: '[data-testid="single-listing-21"] *',
    });

    // listing tags
    const functionalTag = getByText('functional', {
      selector: '[data-testid="single-listing-21"] a',
    });

    expect(functionalTag.getAttribute('href')).toEqual(
      '/listings?t=functional',
    );

    const clojureTag = getByText('clojure', {
      selector: '[data-testid="single-listing-21"] a',
    });

    expect(clojureTag.getAttribute('href')).toEqual('/listings?t=clojure');

    // listing author
    const listing2Author = getByText('Mr. Rogers', {
      selector: '[data-testid="single-listing-21"] a',
    });

    expect(listing2Author.getAttribute('href')).toEqual('/fred');

    // 3rd listing
    getByTestId('single-listing-22');

    // listing title
    const listing3Title = getByRole('link', {
      name: 'Illo iure quos perspiciatis',
    });

    expect(listing3Title.getAttribute('href')).toEqual(
      '/listings/misc/illo-iure-fss-ssasas-5hk7',
    );

    // listing body
    getByText(/Bobby says hello. Eius et ullam. Dolores et qui. Quis/, {
      selector: '[data-testid="single-listing-22"] *',
    });

    // listing tags
    const twitterTag = getByText('twitter', {
      selector: '[data-testid="single-listing-22"] a',
    });

    expect(twitterTag.getAttribute('href')).toEqual('/listings?t=twitter');

    const learningTag = getByText('learning', {
      selector: '[data-testid="single-listing-22"] a',
    });

    expect(learningTag.getAttribute('href')).toEqual('/listings?t=learning');

    const listing3Author = getByText('Mrs. John Mack', {
      selector: '[data-testid="single-listing-22"] a',
    });

    expect(listing3Author.getAttribute('href')).toEqual('/mrsjohnmack');
  });
});
