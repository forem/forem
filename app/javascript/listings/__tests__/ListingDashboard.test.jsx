import { h } from 'preact';
import {
  render,
  fireEvent,
  cleanup,
  screen,
  within,
} from '@testing-library/preact';
import { JSDOM } from 'jsdom';
import { axe } from 'jest-axe';
import '@testing-library/jest-dom';

import '../../../assets/javascripts/utilities/localDateTime';
import { ListingDashboard } from '../listingDashboard';

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

const orgListing = [
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
];

const orgs = [
  { id: 2, name: 'Yoyodyne', slug: 'org3737', unspent_credits_count: 1 },
  { id: 3, name: 'Infotrode', slug: 'org5254', unspent_credits_count: 1 },
];

const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;

global.document.body.innerHTML = `<div id="listings-dashboard" data-listings=${JSON.stringify(
  listingsForDataAttribute,
)} data-usercredits="3" data-orglistings=${JSON.stringify(
  orgListing,
)} data-orgs=${JSON.stringify(orgs)} ></div>`;
global.window = doc.defaultView;

const listings = {
  listings: listingsForDataAttribute,
  orgListings: orgListing,
  orgs,
  userCredits: '3',
  selectedListings: 'user',
};

/* eslint-disable no-unused-vars */
/* global globalThis timestampToLocalDateTimeLong timestampToLocalDateTimeShort */

const setup = () => {
  return render(<ListingDashboard />);
};

describe('<ListingDashboard />', () => {
  afterAll(() => {
    delete globalThis.timestampToLocalDateTimeLong;
    delete globalThis.timestampToLocalDateTimeShort;
  });

  beforeEach(setup);

  describe('Acessbility check', () => {
    beforeAll(cleanup);

    it('should have no a11y violations', async () => {
      const { container } = render(<ListingDashboard />);
      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });
  });

  it('should render for user and org buttons', () => {
    const secondOrg = screen.getByRole('button', {
      name: listings.orgs[1].name,
    });

    expect(
      screen.getByRole('button', { name: 'Personal' }),
    ).toBeInTheDocument();
    expect(secondOrg).toBeInTheDocument();
  });

  it('should make button active when clicking on it', () => {
    const firstOrg = screen.getByRole('button', {
      name: listings.orgs[0].name,
    });
    fireEvent.click(firstOrg);

    expect(firstOrg.classList.contains('active')).toEqual(true);
  });

  it('should render listing and credits header with links', () => {
    const listingHeading = screen.getByRole('heading', {
      level: 3,
      name: 'Listings',
    });
    const creditsHeading = screen.getByRole('heading', {
      name: 'Credits',
      level: 3,
    });

    const createListing = screen.getByRole('link', {
      name: 'Create a Listing',
    });
    const buyCredits = screen.getByRole('link', { name: 'Buy Credits' });

    expect(listingHeading).toBeInTheDocument();
    expect(creditsHeading).toBeInTheDocument();
    expect(createListing).toBeInTheDocument();

    expect(createListing.getAttribute('href')).toEqual('/listings/new');
    expect(buyCredits).toBeInTheDocument();
    expect(buyCredits.getAttribute('href')).toEqual('/credits/purchase');
  });

  describe('1st listing', () => {
    it('should render the edit and delete buttons', () => {
      const firstListing = screen.getByTestId('23');
      const firstListingContainer = within(firstListing);

      const editButton = firstListingContainer.getByRole('link', {
        name: 'Edit',
      });

      expect(editButton.nodeName).toEqual('A');
      expect(editButton.getAttribute('href')).toEqual('/listings/23/edit');

      const deleteButton = firstListingContainer.getByRole('link', {
        name: 'Delete',
      });

      expect(deleteButton.nodeName).toEqual('A');
      expect(deleteButton.getAttribute('href')).toEqual(
        '/listings/cfp/asdfasdf-2ea8/delete_confirm',
      );
    });

    it('should render the listing title and the time', () => {
      const title = screen.getByRole('heading', {
        name: 'asdfasdf (expired)',
        level: 2,
      });
      const timer = screen.getByTitle(
        /Tuesday, June 11, 2019(,| at) 4:45:37 PM/,
      );

      expect(title).toBeInTheDocument();
      expect(timer).toBeInTheDocument();
    });

    it('should render the listing category', () => {
      const firstListing = screen.getByTestId('23');
      const firstListingContainer = within(firstListing);

      const listing1CfpCategory = firstListingContainer.getByRole('link', {
        name: 'cfp',
      });
      expect(listing1CfpCategory.getAttribute('href')).toEqual('/listings/cfp');
    });

    it('should render the listing tags', () => {
      const firstListing = screen.getByTestId('23');
      const firstListingContainer = within(firstListing);

      const listing1ComputerScienceTag = firstListingContainer.getByRole(
        'link',
        { name: '#computerscience' },
      );
      expect(listing1ComputerScienceTag.getAttribute('href')).toEqual(
        '/listings?t=computerscience',
      );

      const careerTag = firstListingContainer.getByRole('link', {
        name: '#career',
      });
      expect(careerTag.getAttribute('href')).toEqual('/listings?t=career');
    });
  });

  describe('2nd listing', () => {
    it('should render the edit and delete buttons', () => {
      const secondListing = screen.getByTestId('24');
      const secondListingContainer = within(secondListing);

      const listing2EditLink = secondListingContainer.getByRole('link', {
        name: 'Edit',
      });

      expect(listing2EditLink.getAttribute('href')).toEqual(
        '/listings/24/edit',
      );

      const listing2DeleteLink = secondListingContainer.getByRole('link', {
        name: 'Delete',
      });

      expect(listing2DeleteLink.getAttribute('href')).toEqual(
        '/listings/events/yoyoyoyoyoooooooo-4jcb/delete_confirm',
      );
    });

    it('should render the listing title and the time', () => {
      const title = screen.getByRole('heading', {
        name: 'YOYOYOYOYOOOOOOOO (expired)',
        level: 2,
      });
      const timer = screen.getByTitle(
        /Tuesday, June 11, 2019(,| at) 4:45:37 PM/,
      );

      expect(title).toBeInTheDocument();
      expect(timer).toBeInTheDocument();
    });

    it('should render the listing category', () => {
      const secondListing = screen.getByTestId('24');
      const secondListingContainer = within(secondListing);

      const listing2EventsCategory = secondListingContainer.getByRole('link', {
        name: 'events',
      });
      expect(listing2EventsCategory.getAttribute('href')).toEqual(
        '/listings/events',
      );
    });

    it('should render the listing tags', () => {
      const secondListing = screen.getByTestId('24');
      const secondListingContainer = within(secondListing);

      const listing2ComputerScienceTag = secondListingContainer.getByRole(
        'link',
        {
          name: '#computerscience',
        },
      );
      const listing2careerTag = secondListingContainer.getByRole('link', {
        name: '#career',
      });
      const conferenceTag = secondListingContainer.getByRole('link', {
        name: '#conference',
      });

      expect(listing2ComputerScienceTag.getAttribute('href')).toEqual(
        '/listings?t=computerscience',
      );
      expect(listing2careerTag.getAttribute('href')).toEqual(
        '/listings?t=career',
      );
      expect(conferenceTag.getAttribute('href')).toEqual(
        '/listings?t=conference',
      );
    });
  });

  describe('3rd listing', () => {
    it('should render the edit and delete buttons', () => {
      const thirdListing = screen.getByTestId('25');
      const thirdListingContainer = within(thirdListing);

      const listing3EditButton = thirdListingContainer.getByRole('link', {
        name: 'Edit',
      });
      const listing3DeleteButton = thirdListingContainer.getByRole('link', {
        name: 'Delete',
      });

      expect(listing3EditButton.getAttribute('href')).toEqual(
        '/listings/25/edit',
      );
      expect(listing3DeleteButton.getAttribute('href')).toEqual(
        '/listings/cfp/hehhehe-5hld/delete_confirm',
      );
    });

    it('should render the listing title and the time', () => {
      const title = screen.getByRole('heading', {
        name: 'hehhehe (expired)',
        level: 2,
      });
      const time = screen.getByTitle(
        /Thursday, April 11, 2019(,| at) 5:01:25 PM/,
      );

      expect(title).toBeInTheDocument();
      expect(time).toBeInTheDocument();
    });

    it('should render the listing category', () => {
      const thirdListing = screen.getByTestId('25');
      const thirdListingContainer = within(thirdListing);

      const listing3CfpCategory = thirdListingContainer.getByRole('link', {
        name: 'cfp',
      });

      expect(listing3CfpCategory.getAttribute('href')).toEqual('/listings/cfp');
    });

    it('should NOT render the listing tags', () => {
      const thirdListing = screen.getByTestId('25');
      const thirdListingContainer = within(thirdListing);

      expect(
        thirdListingContainer.queryByRole('link', { name: /#/ }),
      ).not.toBeInTheDocument();
    });
  });
});
