import { h } from 'preact';
import { render } from '@testing-library/preact';
import { screen } from '@testing-library/dom';

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
  xit('should load a single user listing', () => {
    const tree = render(
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
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  describe('should load the following elements', () => {

    it('for listing title', () => {
      const { getByText } = render(
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
        />,
      );
      getByText('Illo iure quos perspiciatis.');
    });

    it('for the dropdown', () => {
      const { getByLabelText, getByText } = render(
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
        />,
      );
      const dropdownButton = getByLabelText(/toggle dropdown menu/i);
      getByText(/report abuse/i);
    });

    it('for listing tags', () => {
      const { getByText } = render(
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
        />,
      );

      listing.tags.forEach((tag) => {
        expect(getByText(tag).href).toContain(`/listings?t=${tag}`);
      });
    });

    it('for listing category', () => {
      const { getByText } = render(
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
        />,
      );

      const { category } = listing;
      expect(getByText(category).href).toContain(`/listings/${category}`);
    });

    it('for listing author', () => {
      const { getByText } = render(
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
        />,
      );

      expect(getByText('Mrs. Yoko Christiansen').href).toContain(`/mrschristiansenyoko`);
    });

    it('for listing location', () => {
      const { getByTestId } = render(
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
        />,
      );

      expect(getByTestId('single-listing-location').href).toContain(`/listings/?q=West%20Refugio`);
    });
  });
});
