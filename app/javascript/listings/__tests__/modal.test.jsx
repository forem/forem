import { h } from 'preact';
import { deep } from 'preact-render-spy';
import Modal from '../elements/modal';

const DefaultListing = {
  id: 22,
  category: 'misc',
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

const idFromMessageModal = 'listings-message-form';

const defaultProps = {
  currentUserId: 1,
  onAddTag: () => {
    return 'onAddTag';
  },
  onChange: () => {
    return 'onChange';
  },
  onClick: () => {
    return 'OnClick';
  },
  onChangeCategory: () => {
    return 'onChangeCategory';
  },
  onOpenModal: () => {
    return 'onOpenModal';
  },
  onSubmit: () => {
    return 'onSubmit;';
  },
  message: 'Something',
};

const renderModal = (listing) =>
  deep(<Modal {...defaultProps} listing={listing} />);

describe('<Modal />', () => {
  it('Should render the MessageModal component when the listing.contact_via_connect is true', () => {
    const listingWithContactViaConnectTrue = {
      ...DefaultListing,
      contact_via_connect: true,
    };
    const context = renderModal(listingWithContactViaConnectTrue);
    expect(context.find(`#${idFromMessageModal}`).exists()).toBe(true);
  });

  it('Should not render the MessageModal when the listing.contact_via_connect is false', () => {
    const listingWithContactViaConnectFalse = {
      ...DefaultListing,
      contact_via_connect: false,
    };
    const context = renderModal(listingWithContactViaConnectFalse);
    expect(context.find(`#${idFromMessageModal}`).exists()).toBe(false);
  });
});
