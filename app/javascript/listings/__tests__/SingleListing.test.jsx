import { h } from 'preact';
import { axe } from 'jest-axe';
import { render } from '@testing-library/preact';

import SingleListing from '../singleListing';

const listing = {
  id: 22,
  category: 'misc',
  contact_via_connect: true,
  location: 'West Refugio',
  processed_html:
    '\u003cp\u003eEius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
  slug: 'illo-iure-quos-perspiciatis-5hk7',
  title: 'Illo iure quos perspiciatis.',
  user_id: 7,
  tags: ['go', 'git'],
  author: {
    name: 'Mrs. Yoko Christiansen',
    username: 'mrschristiansenyoko',
    profile_image_90:
      '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
  },
};

describe('<SingleListing />', () => {
  const renderSingleListing = () => render(
    <SingleListing
      onAddTag={() => {
        return 'onAddTag';
      }}
      onChangeCategory={() => {
        return 'onChangeCategory';
      }}
      listing={listing}
      currentUserId={1}
      onOpenModal={() => {
        return 'onOpenModal';
      }}
      isOpen={false}
    />
  );

  it('should have no a11y violations', async () => {
    const { container } = renderSingleListing();
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('shows a listing title', () => {
    const { getByText } = renderSingleListing();
    getByText('Illo iure quos perspiciatis.');
  });

  it('shows a dropdown', () => {
    const { getByLabelText, getByText } = renderSingleListing();
    const dropdownButton = getByLabelText(/toggle dropdown menu/i);
    getByText(/report abuse/i);
  });

  it('shows a listing tags', () => {
    const { getByText } = renderSingleListing();
    listing.tags.forEach((tag) => {
      expect(getByText(tag).href).toContain(`/listings?t=${tag}`);
    });
  });

  it('shows a listing category', () => {
    const { getByText } = renderSingleListing();
    const { category } = listing;
    expect(getByText(category).href).toContain(`/listings/${category}`);
  });

  it('shows a listing author', () => {
    const { getByText } = renderSingleListing();
    expect(getByText('Mrs. Yoko Christiansen').href).toContain(`/mrschristiansenyoko`);
  });

  it('shows a listing location', () => {
    const { getByTestId } = renderSingleListing();
    expect(getByTestId('single-listing-location').href).toContain(`/listings/?q=West%20Refugio`);
  });
});
