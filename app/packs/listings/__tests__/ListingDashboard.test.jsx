import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { JSDOM } from 'jsdom';
import { axe } from 'jest-axe';

import '../../../assets/javascripts/utilities/localDateTime';

import { ListingDashboard } from '../listingDashboard';

const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;
const listingsForDataAttribute = [
  {
    id: 23,
    bumped_at: '2019-06-11T16:45:37.229Z',
    category: 'cfp',
    organization_id: null,
    slug: 'asdfasdf-2ea8',
    title: 'asdfasdf',
    updated_at: '2019-06-11T16:45:37.237Z',
    user_id: 11,
    tag_list: ['computerscience', 'career'],
    author: {
      name: 'MarioSee',
      username: 'mariocsee',
      profile_image_90:
        '/uploads/user/profile_image/11/e594d777-b57b-41d6-a793-5d8127bd11b3.jpeg',
    },
  },
  {
    id: 24,
    bumped_at: '2019-05-11T16:59:16.312Z',
    category: 'events',
    organization_id: 2,
    slug: 'yoyoyoyoyoooooooo-4jcb',
    title: 'YOYOYOYOYOOOOOOOO',
    updated_at: '2019-05-11T16:59:16.316Z',
    user_id: 11,
    tag_list: ['computerscience', 'conference', 'career'],
    author: {
      name: 'Yoyodyne',
      username: 'org3737',
      profile_image_90:
        '/uploads/organization/profile_image/2/5edb1e49-bea9-4e99-bc32-acc10c52a935.png',
    },
  },
  {
    id: 25,
    bumped_at: '2019-04-11T17:01:25.143Z',
    category: 'cfp',
    organization_id: 3,
    slug: 'hehhehe-5hld',
    title: 'hehhehe',
    updated_at: '2019-04-11T17:01:25.169Z',
    user_id: 11,
    tag_list: [],
    author: {
      name: 'Infotrode',
      username: 'org5254',
      profile_image_90:
        '/uploads/organization/profile_image/3/04d4e1f1-c2e0-4147-81e2-bc8a2657296b.png',
    },
  },
];
global.document.body.innerHTML = `<div id="listings-dashboard" data-listings=${JSON.stringify(
  listingsForDataAttribute,
)} data-usercredits="3" data-orglistings=${JSON.stringify([
  {
    id: 24,
    bumped_at: '2019-06-11T16:59:16.312Z',
    category: 'events',
    organization_id: 2,
    slug: 'yoyoyoyoyoooooooo-4jcb',
    title: 'YOYOYOYOYOOOOOOOO',
    updated_at: '2019-06-11T16:59:16.316Z',
    user_id: 11,
    tag_list: ['computerscience', 'conference', 'career'],
    author: {
      name: 'Yoyodyne',
      username: 'org3737',
      profile_image_90:
        '/uploads/organization/profile_image/2/5edb1e49-bea9-4e99-bc32-acc10c52a935.png',
    },
  },
  {
    id: 25,
    bumped_at: '2019-06-11T17:01:25.143Z',
    category: 'cfp',
    organization_id: 3,
    slug: 'hehhehe-5hld',
    title: 'hehhehe',
    updated_at: '2019-06-11T17:01:25.169Z',
    user_id: 11,
    tag_list: [],
    author: {
      name: 'Infotrode',
      username: 'org5254',
      profile_image_90:
        '/uploads/organization/profile_image/3/04d4e1f1-c2e0-4147-81e2-bc8a2657296b.png',
    },
  },
])} data-orgs=${JSON.stringify([
  { id: 2, name: 'Yoyodyne', slug: 'org3737', unspent_credits_count: 1 },
  { id: 3, name: 'Infotrode', slug: 'org5254', unspent_credits_count: 1 },
])} ></div>`;
global.window = doc.defaultView;

const listings = {
  listings: [
    {
      id: 23,
      bumped_at: '2019-06-11T16:45:37.229Z',
      category: 'cfp',
      location: 'New York City',
      organization_id: null,
      slug: 'asdfasdf-2ea8',
      title: 'asdfasdf',
      updated_at: '2019-06-11T16:45:37.237Z',
      user_id: 11,
      tag_list: [Array],
      author: [Object],
    },
    {
      id: 24,
      bumped_at: '2019-06-11T16:59:16.312Z',
      category: 'events',
      location: 'Denver',
      organization_id: 2,
      slug: 'yoyoyoyoyoooooooo-4jcb',
      title: 'YOYOYOYOYOOOOOOOO',
      updated_at: '2019-06-11T16:59:16.316Z',
      user_id: 11,
      tag_list: [Array],
      author: [Object],
    },
    {
      id: 25,
      bumped_at: '2019-06-11T17:01:25.143Z',
      category: 'cfp',
      location: 'Seattle',
      organization_id: 3,
      slug: 'hehhehe-5hld',
      title: 'hehhehe',
      updated_at: '2019-06-11T17:01:25.169Z',
      user_id: 11,
      tag_list: [],
      author: [Object],
    },
  ],
  orgListings: [
    {
      id: 24,
      bumped_at: '2019-06-11T16:59:16.312Z',
      category: 'events',
      location: 'Denver',
      organization_id: 2,
      slug: 'yoyoyoyoyoooooooo-4jcb',
      title: 'YOYOYOYOYOOOOOOOO',
      updated_at: '2019-06-11T16:59:16.316Z',
      user_id: 11,
      tag_list: [Array],
      author: [Object],
    },
    {
      id: 25,
      bumped_at: '2019-06-11T17:01:25.143Z',
      category: 'cfp',
      location: 'Seattle',
      organization_id: 3,
      slug: 'hehhehe-5hld',
      title: 'hehhehe',
      updated_at: '2019-06-11T17:01:25.169Z',
      user_id: 11,
      tag_list: [],
      author: [Object],
    },
  ],
  orgs: [
    { id: 2, name: 'Yoyodyne', slug: 'org3737', unspent_credits_count: 1 },
    { id: 3, name: 'Infotrode', slug: 'org5254', unspent_credits_count: 1 },
  ],
  userCredits: '3',
  selectedListings: 'user',
};

/* eslint-disable no-unused-vars */
/* global globalThis timestampToLocalDateTimeLong timestampToLocalDateTimeShort */

describe('<ListingDashboard />', () => {
  afterAll(() => {
    delete globalThis.timestampToLocalDateTimeLong;
    delete globalThis.timestampToLocalDateTimeShort;
  });

  it('should have no a11y violations', async () => {
    const { container } = render(<ListingDashboard />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render for user and org buttons', () => {
    const { getByText } = render(<ListingDashboard />);

    getByText('Personal', { selector: '[role="button"]' });
    const org1 = getByText(listings.orgs[0].name, {
      selector: '[role="button"]',
    });
    getByText(listings.orgs[1].name, { selector: '[role="button"]' });

    fireEvent.click(org1);

    expect(org1.classList.contains('active')).toEqual(true);
  });

  it('should render for listing and credits header', () => {
    const { getByText } = render(<ListingDashboard />);

    getByText('Listings', { selector: 'h3' });

    const createListing = getByText('Create a Listing', { selector: 'a' });

    expect(createListing.getAttribute('href')).toEqual('/listings/new');

    getByText('Credits', { selector: 'h3' });

    const buyCredits = getByText('Buy Credits', { selector: 'a' });

    expect(buyCredits.getAttribute('href')).toEqual('/credits/purchase');
  });

  it('should render for listingRow view', () => {
    const { getByText } = render(<ListingDashboard />);

    // 1st listing
    const listing1GetByTextOptions = {
      selector: '[data-listing-id="23"] *',
    };

    getByText('asdfasdf (expired)', listing1GetByTextOptions);
    getByText('Jun 11, 2019', listing1GetByTextOptions);

    // listing category
    const listing1CfpCategory = getByText('cfp', listing1GetByTextOptions);

    expect(listing1CfpCategory.getAttribute('href')).toEqual('/listings/cfp');

    // tags
    const listing1ComputerScienceTag = getByText(
      '#computerscience',
      listing1GetByTextOptions,
    );

    expect(listing1ComputerScienceTag.getAttribute('href')).toEqual(
      '/listings?t=computerscience',
    );

    const careerTag = getByText('#career', listing1GetByTextOptions);

    expect(careerTag.getAttribute('href')).toEqual('/listings?t=career');

    // edit and delete buttons
    const editButton = getByText('Edit', listing1GetByTextOptions);

    expect(editButton.nodeName).toEqual('A');
    expect(editButton.getAttribute('href')).toEqual('/listings/23/edit');

    const deleteButton = getByText('Delete', listing1GetByTextOptions);

    expect(deleteButton.nodeName).toEqual('A');
    expect(deleteButton.getAttribute('href')).toEqual(
      '/listings/cfp/asdfasdf-2ea8/delete_confirm',
    );

    // 2nd listing
    const listing2GetByTextOptions = {
      selector: '[data-listing-id="24"] *',
    };

    getByText('YOYOYOYOYOOOOOOOO (expired)', listing2GetByTextOptions);
    getByText('May 11, 2019', listing2GetByTextOptions);

    // listing category
    const listing2EventsCategory = getByText(
      'events',
      listing2GetByTextOptions,
    );

    expect(listing2EventsCategory.getAttribute('href')).toEqual(
      '/listings/events',
    );

    // tags
    const listing2ComputerScienceTag = getByText(
      '#computerscience',
      listing2GetByTextOptions,
    );

    expect(listing2ComputerScienceTag.getAttribute('href')).toEqual(
      '/listings?t=computerscience',
    );

    const listing2careerTag = getByText('#career', listing2GetByTextOptions);

    expect(listing2careerTag.getAttribute('href')).toEqual(
      '/listings?t=career',
    );

    const conferenceTag = getByText('#conference', listing2GetByTextOptions);

    expect(conferenceTag.getAttribute('href')).toEqual(
      '/listings?t=conference',
    );

    // edit and delete buttons
    const listing2EditButton = getByText('Edit', listing2GetByTextOptions);

    expect(listing2EditButton.getAttribute('href')).toEqual(
      '/listings/24/edit',
    );

    const listing2DeleteButton = getByText('Delete', listing2GetByTextOptions);

    expect(listing2DeleteButton.getAttribute('href')).toEqual(
      '/listings/events/yoyoyoyoyoooooooo-4jcb/delete_confirm',
    );

    // 3rd listing
    const listing3GetByTextOptions = {
      selector: '[data-listing-id="25"] *',
    };

    getByText('hehhehe (expired)', listing3GetByTextOptions);
    getByText('Apr 11, 2019', listing3GetByTextOptions);

    // listing category
    const listing3CfpCategory = getByText('cfp', listing3GetByTextOptions);

    expect(listing3CfpCategory.getAttribute('href')).toEqual('/listings/cfp');

    // has no tags

    //     // edit and delete buttons
    const listing3EditButton = getByText('Edit', listing3GetByTextOptions);

    expect(listing3EditButton.getAttribute('href')).toEqual(
      '/listings/25/edit',
    );

    const listing3DeleteButton = getByText('Delete', listing3GetByTextOptions);

    expect(listing3DeleteButton.getAttribute('href')).toEqual(
      '/listings/cfp/hehhehe-5hld/delete_confirm',
    );
  });
});
