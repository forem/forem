import { h } from 'preact';
import { ButtonNew as Button } from '@crayons';

export const MinimalProfilePreviewCard = ({
  triggerId,
  contentId,
  username,
  name,
  profileImage,
  userId,
  subscriber,
}) => (
  <div class="profile-preview-card relative mb-4 s:mb-0 fw-medium hidden m:inline-block">
    <button
      id={triggerId}
      aria-controls={contentId}
      class="profile-preview-card__trigger fs-s p-1 crayons-btn crayons-btn--ghost -ml-1 -my-2"
      aria-label={`${name} profile details`}
    >
      {name} {subscriber === 'true' ? <img class='subscription-icon' src={document.body.dataset.subscriptionIcon} alt='Subscriber' /> : ''}
    </button>

    <div
      id={contentId}
      class="profile-preview-card__content crayons-dropdown p-4 pt-0 branded-7"
      style="border-top-color: var(--card-color);"
      data-repositioning-dropdown="true"
      data-testid="profile-preview-card"
    >
      <div class="gap-4 grid">
        <div class="-mt-4">
          <a href={`/${username}`} class="flex">
            <span class="crayons-avatar crayons-avatar--xl mr-2 shrink-0">
              <img
                src={profileImage}
                class="crayons-avatar__image"
                alt=""
                loading="lazy"
              />
            </span>
            <span class="crayons-link crayons-subtitle-2 mt-5">{name}</span>
          </a>
        </div>
        <div class="print-hidden">
          <Button
            variant="primary"
            className="follow-action-button follow-user w-100"
            data-info={JSON.stringify({
              id: userId,
              className: 'User',
              name,
              style: 'full',
            })}
          >
            Follow
          </Button>
        </div>
        <div
          class="author-preview-metadata-container"
          data-author-id={userId}
        />
      </div>
    </div>
  </div>
);
