import { h } from 'preact';
import { useState } from 'preact/hooks';
import { Icon } from '@crayons';
import FavoriteSVG from '@images/favorite.svg';
import FavoriteFilledSVG from '@images/favorite-filled.svg';
import FavoriteCheckedSVG from '@images/favorite-checked.svg';
import SmallFavoriteSVG from '@images/small-favorite.svg';
import SmallFavoriteFilledSVG from '@images/small-favorite-filled.svg';
import SmallFavoriteCheckedSVG from '@images/small-favorite-checked.svg';
import { makeFavorite } from './favoriteService';

// The article bar gets the full-size icon, comments the compact one.
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
};

const controlClass = (variant, favorited) =>
  [
    VARIANT_CLASS[variant] || VARIANT_CLASS.article,
    'favorite-control',
    favorited && 'favorite-control--favorited',
    'crayons-tooltip__activator relative',
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
    />
  );
  if (variant === 'comment') {
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
  labelFavorite,
  labelFavorited,
  labelFavoritedByYou,
}) => {
  const [favorited, setFavorited] = useState(
    initialFavorited === 'true' || initialFavorited === true,
  );
  const [favoritedById, setFavoritedById] = useState(
    initialFavoritedByUserId ? Number(initialFavoritedByUserId) : null,
  );
  const [submitting, setSubmitting] = useState(false);

  const userId = currentUser?.id ?? null;
  const favoritedByCurrentUser =
    favorited && userId != null && favoritedById === userId;

  if (favorited) {
    const label = favoritedByCurrentUser ? labelFavoritedByYou : labelFavorited;
    return (
      <span class={controlClass(variant, true)} role="img" aria-label={label}>
        <FavoriteIcon
          variant={variant}
          filled
          checked={favoritedByCurrentUser}
        />
        <Tooltip label={label} />
      </span>
    );
  }

  // Only enable favoriting for community leaders for now
  if (!currentUser?.community_leader) {
    return null;
  }

  // A user can't favorite their own content
  if (userId != null && Number(favoritableUserId) === userId) {
    return null;
  }

  const onClick = async () => {
    if (submitting) return;
    setSubmitting(true);
    try {
      const response = await makeFavorite({ favoritableId, favoritableType });
      if (response.ok) {
        setFavorited(true);
        setFavoritedById(userId);
        return;
      }

      const { error, code } = await response.json().catch(() => ({}));

      if (code === 'already_favorited') {
        setFavorited(true);
        setFavoritedById(null);
      }

      if (error && typeof window.top.addSnackbarItem === 'function') {
        window.top.addSnackbarItem({ message: error, addCloseButton: true });
      }
    } finally {
      setSubmitting(false);
    }
  };

  return (
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
  );
};
