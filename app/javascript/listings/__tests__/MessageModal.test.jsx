import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import MessageModal from '../components/MessageModal';

const getDefaultListing = () => ({
  id: 22,
  category: 'misc',
  location: 'West Refugio',
  processed_html:
    '\u003cp\u003eEius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
  slug: 'illo-iure-quos-perspiciatis-5hk7',
  title: 'Illo iure quos perspiciatis.',
  tags: ['go', 'git'],
  user_id: 1,
  author: {
    name: 'Mrs. Yoko Christiansen',
    username: 'mrschristiansenyoko',
    profile_image_90:
      '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
  },
});

const getProps = () => ({
  currentUserId: 1,
  message: 'Something',
  onChangeDraftingMessage: jest.fn(),
  onSubmit: jest.fn()
});

const renderMessageModal = (listing) => render(
  <MessageModal {...getProps()} listing={listing} />
);

describe('<MessageModal />', () => {
  it('should render a text-area', () => {
    const { getByTestId } = renderMessageModal(getDefaultListing());
    getByTestId('listing-new-message');
  });

  describe('When the current user is the author', () => {
    const listingWithCurrentUserId = {
      ...getDefaultListing(),
      user_id: 1,
    };

    it('should show the information about contact with the current user', () => {
      const { getByText } = renderMessageModal(listingWithCurrentUserId);
      getByText('This is your active listing. Any member can contact you via this form.')
    });

    it('should show the personalized message about the interactions', () => {
      const { getByTestId } = renderMessageModal(listingWithCurrentUserId);
      expect(getByTestId('personal-message-about-interactions').textContent).toEqual('All private interactions must abide by the code of conduct')
    });
  });

  describe('When current user is not the author', () => {
    const listingWithDifferentCurrentUserId = {
      ...getDefaultListing(),
      user_id: 111,
    };

    it('should show the message to contact the author', () => {
      const { getByText } = renderMessageModal(listingWithDifferentCurrentUserId);

      getByText(`Contact ${listingWithDifferentCurrentUserId.author.name} via DEV Connect`);
    });

    it('should show a generic message about the interactions', () => {
      const { getByTestId } = renderMessageModal(listingWithDifferentCurrentUserId);
      expect(getByTestId('generic-message-about-interactions').textContent).toEqual(
        'Message must be relevant and on-topic with the listing. All private interactions must abide by the code of conduct'
      );
    });
  });
});
