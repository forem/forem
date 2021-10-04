import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '../../i18n/l10n';
import { Button } from '@crayons';

export const MessageModal = ({
  currentUserId,
  message,
  listing,
  onSubmit,
  onChangeDraftingMessage,
}) => {
  const isCurrentUserOnListing = listing.user_id === currentUserId;

  return (
    <form
      data-testid="listings-message-modal"
      id="listings-message-form"
      onSubmit={onSubmit}
    >
      <header className="mb-4">
        <h2 className="fs-xl fw-bold lh-tight">
          {i18next.t('listings.message.heading')}
        </h2>
        {isCurrentUserOnListing ? (
          <p className="color-base-70">{i18next.t('listings.message.desc1')}</p>
        ) : (
          <p className="color-base-70">
            {i18next.t('listings.message.desc2', { name: listing.author.name })}
          </p>
        )}
      </header>
      <textarea
        value={message}
        onChange={onChangeDraftingMessage}
        data-testid="listing-new-message"
        id="new-message"
        className="crayons-textfield mb-0"
        placeholder={i18next.t('listings.message.placeholder')}
        aria-label={i18next.t('listings.message.aria_label')}
      />
      <p
        className="mb-4 fs-s color-base-60"
        // eslint-disable-next-line react/no-danger
        dangerouslySetInnerHTML={{
          __html:
            (isCurrentUserOnListing && i18next.t('listings.message.relevant')) +
            i18next.t('listings.message.notice', {
              code: `<a href="/code-of-conduct" className="crayons-link crayons-link--brand">${i18next.t(
                'listings.message.code',
              )}</a>`,
              interpolation: { escapeValue: false },
            }),
        }}
      />
      <div className="flex">
        <Button
          variant="primary"
          className="mr-2"
          tagName="button"
          type="submit"
        >
          {i18next.t('listings.message.submit')}
        </Button>
      </div>
    </form>
  );
};

MessageModal.propTypes = {
  currentUserId: PropTypes.number.isRequired,
  message: PropTypes.string.isRequired,
  listing: PropTypes.shape({
    author: PropTypes.shape({
      name: PropTypes.string.isRequired,
    }).isRequired,
    user_id: PropTypes.number.isRequired,
  }).isRequired,
  onSubmit: PropTypes.func.isRequired,
  onChangeDraftingMessage: PropTypes.func.isRequired,
};
