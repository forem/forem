import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Modal } from '../components/Modal';

import '../../../assets/javascripts/utilities/localDateTime';

/* eslint-disable no-unused-vars */
/* global globalThis timestampToLocalDateTimeLong timestampToLocalDateTimeShort */
describe('<Modal />', () => {
  afterAll(() => {
    delete globalThis.timestampToLocalDateTimeLong;
    delete globalThis.timestampToLocalDateTimeShort;
  });

  const getDefaultListing = () => ({
    id: 22,
    category: 'misc',
    location: 'West Refugio',
    processed_html:
      '\u003cp\u003eEius et ullam. Dolores et qui. Quis \u003cstrong\u003equi\u003c/strong\u003e omnis.\u003c/p\u003e\n',
    slug: 'illo-iure-quos-perspiciatis-5hk7',
    title: 'Illo iure quos perspiciatis.',
    bumped_at: '2020-09-06T14:15:02.977Z',
    originally_published_at: '2020-09-06T14:15:02.977Z',
    user_id: 7,
    tags: ['go', 'git'],
    author: {
      name: 'Mrs. Yoko Christiansen',
      username: 'mrschristiansenyoko',
      profile_image_90:
        '/uploads/user/profile_image/7/4b1c980a-beb0-4a5f-b3f2-acc91adc503c.png',
    },
  });

  const getProps = () => ({
    currentUserId: 1,
    onAddTag: () => {
      return 'onAddTag';
    },
    onChangeDraftingMessage: () => {
      return 'onChangeDraftingMessage';
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
  });

  const renderModal = (listing) =>
    render(<Modal {...getProps()} listing={listing} />);

  it('should have no a11y violations', async () => {
    const { container } = renderModal({ ...getDefaultListing() });
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should render the MessageModal component when the listing.contact_via_connect is true', () => {
    const listingWithContactViaConnectTrue = {
      ...getDefaultListing(),
      contact_via_connect: true,
    };
    const { queryByTestId } = renderModal(listingWithContactViaConnectTrue);

    expect(queryByTestId('listings-message-modal')).toBeDefined();
  });

  it('should not render the MessageModal when the listing.contact_via_connect is false', () => {
    const listingWithContactViaConnectFalse = {
      ...getDefaultListing(),
      contact_via_connect: false,
    };
    const { queryByTestId } = renderModal(listingWithContactViaConnectFalse);
    expect(queryByTestId('listings-message-modal')).toBeNull();
  });
});
