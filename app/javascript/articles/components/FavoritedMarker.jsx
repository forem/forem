import { h } from 'preact';
import PropTypes from 'prop-types';
import { Icon } from '@crayons';
import SmallFavoriteFilledSVG from '@images/small-favorite-filled.svg';
import SmallFavoriteCheckedSVG from '@images/small-favorite-checked.svg';
import { globalFeatureFlagEnabled } from '../../utilities/featureFlags';

export const FavoritedMarker = ({ favoritedByUserId, currentUserId }) => {
  if (!favoritedByUserId || !globalFeatureFlagEnabled('community_favorites')) {
    return null;
  }

  // eslint-disable-next-line eqeqeq
  const favoritedByViewer =
    currentUserId != null && favoritedByUserId == currentUserId;
  const label = favoritedByViewer ? 'Favorited by you' : 'Favorited';

  return (
    <span className="crayons-story__favorited" data-favorited-marker>
      <span className="favorited-marker" role="img" aria-label={label}>
        <Icon
          src={
            favoritedByViewer ? SmallFavoriteCheckedSVG : SmallFavoriteFilledSVG
          }
          native
          aria-hidden="true"
          focusable="false"
        />
      </span>
    </span>
  );
};

FavoritedMarker.propTypes = {
  favoritedByUserId: PropTypes.number,
  currentUserId: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
};

FavoritedMarker.displayName = 'FavoritedMarker';
