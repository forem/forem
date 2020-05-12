import { h } from 'preact';
import render from 'preact-render-to-json';
import AllListings from '../components/AllListings';

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
    name: 'Mrs. Yoko Christiansen',
    username: 'mrschristiansenyoko',
    profile_image_90:
      '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
  },
};

const secondtListing = {
  id: 21,
  category: 'misc',
  location: 'West Refugio',
  processed_html:
    '\u003cp\u003eEius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
  slug: 'illo-iure-quos-ereerr-5hk7',
  title: 'Second tag.',
  tags: ['functional', 'clojure'],
  user_id: 1,
  author: {
    name: 'Mrs. Ashahir',
    username: 'mrschristiansenyoko',
    profile_image_90:
      '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
  },
};

const thirdListing = {
  id: 22,
  category: 'misc',
  location: 'West Refugio',
  processed_html:
    '\u003cp\u003eEius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
  slug: 'illo-iure-fss-ssasas-5hk7',
  title: 'Illo iure quos perspiciatis.',
  tags: ['twitter', 'learning'],
  user_id: 1,
  author: {
    name: 'Mrs. John Mack',
    username: 'mrschristiansenyoko',
    profile_image_90:
      '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
  },
};

const listings = [firstListing, secondtListing, thirdListing];

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

describe('<AllListings />', () => {
  it('Should render all listings', () => {
    const context = renderAllListings();
    expect(context).toMatchSnapshot();
  });
});
