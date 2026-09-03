import { h, Fragment } from 'preact';
import { useState } from 'preact/hooks';
import { Icon, Modal, ButtonNew as Button } from '@crayons';
import FavoriteSVG from '@images/favorite.svg';
import FavoriteFilledSVG from '@images/favorite-filled.svg';
import FavoriteCheckedSVG from '@images/favorite-checked.svg';
import SmallFavoriteSVG from '@images/small-favorite.svg';
import SmallFavoriteFilledSVG from '@images/small-favorite-filled.svg';
import SmallFavoriteCheckedSVG from '@images/small-favorite-checked.svg';
import { makeFavorite } from './favoriteService';

// The article bar gets the full-size icon, comments and dropdowns the compact one.
const ICONS = {
  article: {
    outline: FavoriteSVG,
    filled: FavoriteFilledSVG,
    checked: FavoriteCheckedSVG,
  },
  comment: {
    outline: SmallFavoriteSVG,
    filled: SmallFavoriteFilledSVG,
    checked: SmallFavoriteCheckedSVG,
  },
  dropdown: {
    outline: SmallFavoriteSVG,
    filled: SmallFavoriteFilledSVG,
    checked: SmallFavoriteCheckedSVG,
  },
};

const iconFor = (variant, filled, checked) => {
  const set = ICONS[variant] || ICONS.article;
  if (!filled) {
    return set.outline;
  }
  return checked ? set.checked : set.filled;
};

const VARIANT_CLASS = {
  article: 'favorite-reaction',
  comment: 'crayons-btn crayons-btn--ghost crayons-btn--s crayons-btn--icon',
  dropdown: 'flex justify-between crayons-link crayons-link--block w-100 bg-transparent border-0',
};

const controlClass = (variant, favorited) =>
  [
    VARIANT_CLASS[variant] || VARIANT_CLASS.article,
    'favorite-control',
    favorited && 'favorite-control--favorited',
    variant !== 'dropdown' && 'crayons-tooltip__activator relative',
  ]
    .filter(Boolean)
    .join(' ');

const FavoriteIcon = ({ variant, filled = false, checked = false }) => {
  const gem = (
    <Icon
      src={iconFor(variant, filled, checked)}
      native
      aria-hidden="true"
      focusable="false"
      class={variant === 'dropdown' ? 'mx-2 shrink-0' : undefined}
    />
  );
  if (variant === 'comment' || variant === 'dropdown') {
    return gem;
  }
  return (
    <span class="crayons-reaction__icon crayons-reaction__icon--borderless">
      {gem}
    </span>
  );
};

const Tooltip = ({ label }) => (
  <span data-testid="tooltip" class="crayons-tooltip__content">
    {label}
  </span>
);

/**
 * Control for marking content as favorite.
 */
export const FavoriteControl = ({
  currentUser,
  variant = 'article',
  favoritableType,
  favoritableId,
  favoritableUserId,
  favorited: initialFavorited,
  favoritedByUserId: initialFavoritedByUserId,
  labelFavorite = 'Pick as gem',
  labelFavorited = 'Picked as gem',
  labelFavoritedByYou = 'Picked as gem by you',
  modalTitle = 'Gem Picked!',
  modalBody = "You've picked this as a community gem!",
  modalRemainingZero = 'You have no more gems left to give out today.',
  modalRemainingOne = 'You have 1 more gem left to give out today.',
  modalRemainingOther = 'You have %{count} more gems left to give out today.',
  modalClose = 'Got it',
  modalExhaustedTitle = 'Out of Gems',
  modalExhaustedBody = 'You have no more gems left to give out today. Your allowance will refresh soon!',
  modalExhaustedClose = 'Got it',
}) => {
  const [favorited, setFavorited] = useState(
    initialFavorited === 'true' || initialFavorited === true,
  );
  const [favoritedById, setFavoritedById] = useState(
    initialFavoritedByUserId ? Number(initialFavoritedByUserId) : null,
  );
  const [submitting, setSubmitting] = useState(false);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [showExhaustedModal, setShowExhaustedModal] = useState(false);
  const [remainingAllowance, setRemainingAllowance] = useState(null);

  const userId = currentUser?.id ?? null;
  const favoritedByCurrentUser =
    favorited && userId != null && favoritedById === userId;

  const renderSuccessModal = () => {
    if (!showSuccessModal) {
      return null;
    }

    let remainingText = modalRemainingOther.replace(
      '%{count}',
      String(remainingAllowance ?? 0),
    );
    if (remainingAllowance === 1) {
      remainingText = modalRemainingOne;
    } else if (remainingAllowance === 0) {
      remainingText = modalRemainingZero;
    }

    return (
      <Modal
        title={modalTitle}
        onClose={() => setShowSuccessModal(false)}
        backdropDismissible
        size="small"
      >
        <div class="p-6 text-center grid gap-4" data-testid="gem-modal-content">
          <div
            class="mx-auto flex items-center justify-center"
            style={{
              width: '96px',
              height: '96px',
              color: 'var(--reaction-favorite-color, #7026b8)',
            }}
          >
            <FavoriteCheckedSVG
              aria-hidden="true"
              focusable="false"
              width="96"
              height="96"
              style={{ width: '96px', height: '96px' }}
            />
          </div>
          <p class="fs-l fw-bold m-0">{modalBody}</p>
          <p class="fs-base color-base-70 m-0">{remainingText}</p>
          <div class="mt-2">
            <Button
              variant="primary"
              size="large"
              onClick={() => setShowSuccessModal(false)}
            >
              {modalClose}
            </Button>
          </div>
        </div>
      </Modal>
    );
  };

  const renderExhaustedModal = () => {
    if (!showExhaustedModal) {
      return null;
    }

    return (
      <Modal
        title={modalExhaustedTitle}
        onClose={() => setShowExhaustedModal(false)}
        backdropDismissible
        size="small"
      >
        <div class="p-6 text-center grid gap-4" data-testid="gem-exhausted-modal-content">
          <div
            class="mx-auto flex items-center justify-center"
            style={{
              width: '96px',
              height: '96px',
              color: 'var(--base-60, #717171)',
            }}
          >
            <FavoriteSVG
              aria-hidden="true"
              focusable="false"
              width="96"
              height="96"
              style={{ width: '96px', height: '96px' }}
            />
          </div>
          <p class="fs-base color-base-70 m-0">{modalExhaustedBody}</p>
          <div class="mt-2">
            <Button
              variant="secondary"
              size="large"
              onClick={() => setShowExhaustedModal(false)}
            >
              {modalExhaustedClose}
            </Button>
          </div>
        </div>
      </Modal>
    );
  };

  if (favorited) {
    const label = favoritedByCurrentUser ? labelFavoritedByYou : labelFavorited;
    if (variant === 'dropdown') {
      return (
        <Fragment>
          <span
            class={controlClass(variant, true)}
            role="img"
            aria-label={label}
          >
            <span class="fw-bold">{label}</span>
            <FavoriteIcon
              variant={variant}
              filled
              checked={favoritedByCurrentUser}
            />
          </span>
          {renderSuccessModal()}
          {renderExhaustedModal()}
        </Fragment>
      );
    }

    return (
      <Fragment>
        <span class={controlClass(variant, true)} role="img" aria-label={label}>
          <FavoriteIcon
            variant={variant}
            filled
            checked={favoritedByCurrentUser}
          />
          <Tooltip label={label} />
        </span>
        {renderSuccessModal()}
        {renderExhaustedModal()}
      </Fragment>
    );
  }

  // Community leaders and users with favorite allowance get the control
  const canSeeControl =
    currentUser?.community_leader === true ||
    (currentUser?.favorite_allowance != null && currentUser.favorite_allowance > 0);

  if (!canSeeControl) {
    return null;
  }

  // A user can't favorite their own content
  if (userId != null && Number(favoritableUserId) === userId) {
    return null;
  }

  const onClick = async () => {
    if (submitting) return;

    if (currentUser?.favorite_allowance != null && currentUser.favorite_allowance <= 0) {
      setShowExhaustedModal(true);
      return;
    }

    setSubmitting(true);
    try {
      const response = await makeFavorite({ favoritableId, favoritableType });
      if (response.ok) {
        const data = await response.json().catch(() => ({}));
        const remaining =
          data.remaining_allowance ??
          (currentUser?.favorite_allowance != null
            ? Math.max(0, currentUser.favorite_allowance - 1)
            : 0);
        setFavorited(true);
        setFavoritedById(userId);
        setRemainingAllowance(remaining);
        setShowSuccessModal(true);
        return;
      }

      const { error, code } = await response.json().catch(() => ({}));

      if (code === 'already_favorited') {
        setFavorited(true);
        setFavoritedById(null);
      } else if (code === 'no_allowance') {
        setShowExhaustedModal(true);
        return;
      }

      if (error && typeof window.top.addSnackbarItem === 'function') {
        window.top.addSnackbarItem({ message: error, addCloseButton: true });
      }
    } finally {
      setSubmitting(false);
    }
  };

  if (variant === 'dropdown') {
    return (
      <Fragment>
        <button
          type="button"
          class={controlClass(variant, false)}
          aria-label={labelFavorite}
          disabled={submitting}
          onClick={onClick}
        >
          <span class="fw-bold">{labelFavorite}</span>
          <FavoriteIcon variant={variant} />
        </button>
        {renderSuccessModal()}
        {renderExhaustedModal()}
      </Fragment>
    );
  }

  return (
    <Fragment>
      <button
        type="button"
        class={controlClass(variant, false)}
        aria-label={labelFavorite}
        disabled={submitting}
        onClick={onClick}
      >
        <FavoriteIcon variant={variant} />
        <Tooltip label={labelFavorite} />
      </button>
      {renderSuccessModal()}
      {renderExhaustedModal()}
    </Fragment>
  );
};
