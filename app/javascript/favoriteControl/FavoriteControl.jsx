import { h, Fragment } from 'preact';
import { useState, useEffect } from 'preact/hooks';
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

export const FAVORITE_UPDATED_EVENT = 'forem:favorite-updated';

export const syncStoredUserAllowance = (remainingAllowance) => {
  if (typeof document === 'undefined') return;

  const hasGems = remainingAllowance === null || remainingAllowance > 0;
  document.body?.classList?.toggle('gem-allowance-available', hasGems);

  try {
    const rawUser =
      document.body?.dataset?.user ||
      (typeof window !== 'undefined' &&
        window.localStorage?.getItem('current_user'));
    if (!rawUser) return;

    const parsedUser = JSON.parse(rawUser);
    parsedUser.favorite_allowance = remainingAllowance;

    if (typeof parsedUser.config_body_class === 'string') {
      const classes = parsedUser.config_body_class
        .split(/\s+/)
        .filter(Boolean)
        .filter((c) => c !== 'gem-allowance-available');
      if (hasGems && !parsedUser.community_leader) {
        classes.push('gem-allowance-available');
      }
      parsedUser.config_body_class = classes.join(' ');
    }

    const serialized = JSON.stringify(parsedUser);
    if (document.body?.dataset) {
      document.body.dataset.user = serialized;
    }
    if (
      typeof window !== 'undefined' &&
      typeof window.browserStoreCache === 'function'
    ) {
      window.browserStoreCache('set', parsedUser);
    } else if (typeof window !== 'undefined' && window.localStorage) {
      window.localStorage.setItem('current_user', serialized);
      if (parsedUser.config_body_class) {
        window.localStorage.setItem(
          'config_body_class',
          parsedUser.config_body_class,
        );
      }
    }
  } catch (e) {
    // Ignore storage errors in restricted browsing modes
  }
};

const broadcastFavoriteUpdate = (detail) => {
  if (typeof window === 'undefined' || typeof window.dispatchEvent !== 'function') {
    return;
  }
  window.dispatchEvent(new CustomEvent(FAVORITE_UPDATED_EVENT, { detail }));
};

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
  modalRemainingUnlimited = 'You have unlimited gems to give out.',
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
  const [allowance, setAllowance] = useState(
    currentUser !== undefined && currentUser !== null
      ? currentUser.favorite_allowance
      : 0,
  );
  const [submitting, setSubmitting] = useState(false);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [showExhaustedModal, setShowExhaustedModal] = useState(false);
  const [remainingAllowance, setRemainingAllowance] = useState(null);

  useEffect(() => {
    setAllowance(
      currentUser !== undefined && currentUser !== null
        ? currentUser.favorite_allowance
        : 0,
    );
  }, [currentUser?.id, currentUser?.favorite_allowance]);

  useEffect(() => {
    if (initialFavorited === 'true' || initialFavorited === true) {
      setFavorited(true);
    }
    if (initialFavoritedByUserId) {
      setFavoritedById(Number(initialFavoritedByUserId));
    }
  }, [initialFavorited, initialFavoritedByUserId]);

  useEffect(() => {
    const handleFavoriteUpdated = (event) => {
      const detail = event.detail || {};
      if (
        detail.favoritableType === favoritableType &&
        String(detail.favoritableId) === String(favoritableId)
      ) {
        if (detail.favorited !== undefined) {
          setFavorited(Boolean(detail.favorited));
        }
        if (detail.favoritedByUserId !== undefined) {
          setFavoritedById(
            detail.favoritedByUserId != null
              ? Number(detail.favoritedByUserId)
              : null,
          );
        }
      }
      if (detail.remainingAllowance !== undefined) {
        setAllowance(detail.remainingAllowance);
      }
    };

    window.addEventListener(FAVORITE_UPDATED_EVENT, handleFavoriteUpdated);
    return () => {
      window.removeEventListener(FAVORITE_UPDATED_EVENT, handleFavoriteUpdated);
    };
  }, [favoritableType, favoritableId]);

  const userId = currentUser?.id ?? null;
  const favoritedByCurrentUser =
    favorited && userId != null && favoritedById === userId;

  const renderSuccessModal = () => {
    if (!showSuccessModal) {
      return null;
    }

    // A null allowance means the curator is not metered.
    let remainingText = modalRemainingUnlimited;
    if (remainingAllowance === 1) {
      remainingText = modalRemainingOne;
    } else if (remainingAllowance === 0) {
      remainingText = modalRemainingZero;
    } else if (remainingAllowance != null) {
      remainingText = modalRemainingOther.replace(
        '%{count}',
        String(remainingAllowance),
      );
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
    (allowance != null && allowance > 0);

  if (!canSeeControl) {
    return showExhaustedModal ? renderExhaustedModal() : null;
  }

  // A user can't favorite their own content
  if (userId != null && Number(favoritableUserId) === userId) {
    return null;
  }

  const onClick = async () => {
    if (submitting) return;

    if (allowance != null && allowance <= 0) {
      setShowExhaustedModal(true);
      return;
    }

    setSubmitting(true);
    try {
      const response = await makeFavorite({ favoritableId, favoritableType });
      if (response.ok) {
        const data = await response.json().catch(() => ({}));
        const remaining =
          data.remaining_allowance !== undefined
            ? data.remaining_allowance
            : allowance != null
              ? Math.max(0, allowance - 1)
              : null;
        setFavorited(true);
        setFavoritedById(userId);
        setAllowance(remaining);
        setRemainingAllowance(remaining);
        setShowSuccessModal(true);
        syncStoredUserAllowance(remaining);
        broadcastFavoriteUpdate({
          favoritableType,
          favoritableId,
          favorited: true,
          favoritedByUserId: userId,
          remainingAllowance: remaining,
        });
        return;
      }

      const { error, code } = await response.json().catch(() => ({}));

      if (code === 'already_favorited') {
        setFavorited(true);
        setFavoritedById(null);
        broadcastFavoriteUpdate({
          favoritableType,
          favoritableId,
          favorited: true,
          favoritedByUserId: null,
        });
      } else if (code === 'no_allowance') {
        setAllowance(0);
        syncStoredUserAllowance(0);
        broadcastFavoriteUpdate({
          remainingAllowance: 0,
        });
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
