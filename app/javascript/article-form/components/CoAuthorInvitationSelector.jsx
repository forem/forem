import { h } from 'preact';
import PropTypes from 'prop-types';
import { useMemo } from 'preact/hooks';
import { MultiSelectAutocomplete } from '@crayons/MultiSelectAutocomplete/MultiSelectAutocomplete';
import { ButtonNew as Button, Icon } from '@crayons';
import Close from '@images/x.svg';
import { locale } from '@utilities/locale';

const CANDIDATES_PATH = '/co_author_invitations/candidates';

const STATUS_LABEL_KEYS = {
  pending: 'core.article_form_co_author_invitation_pending',
  accepted: 'core.article_form_co_author_invitation_accepted',
};

// MultiSelectAutocomplete identifies options by `name`, so options are keyed
// by username (which is unique) and keep the display name separately.
const toOption = (user, status) => ({
  id: user.id,
  name: user.username,
  fullName: user.name,
  profileImage: user.profile_image_90,
  status,
});

const toUser = (option) => ({
  id: option.id,
  name: option.fullName,
  username: option.name,
  profile_image_90: option.profileImage,
});

const Avatar = ({ src }) => (
  <span className="crayons-avatar crayons-avatar--s mr-2 shrink-0">
    <img className="crayons-avatar__image" src={src} alt="" />
  </span>
);

const CandidateSuggestion = ({ name, fullName, profileImage }) => (
  <div className="flex items-center p-2">
    <Avatar src={profileImage} />
    <span className="fw-medium mr-1">{fullName}</span>
    <span className="color-base-60">@{name}</span>
  </div>
);

const InviteeSelection = ({
  fullName,
  profileImage,
  status,
  buttonVariant,
  onEdit,
  onDeselect,
}) => (
  <div role="group" aria-label={fullName} className="flex mr-1 mb-1 w-max">
    <Button
      variant={buttonVariant}
      className="c-autocomplete--multi__selected p-1 cursor-text flex items-center"
      aria-label={locale('core.article_form_co_author_invitation_edit', {
        name: fullName,
      })}
      onClick={onEdit}
    >
      <Avatar src={profileImage} />
      {fullName}
      <span className="color-base-60 fs-s ml-2">
        {locale(
          STATUS_LABEL_KEYS[status] ||
            'core.article_form_co_author_invitation_new',
        )}
      </span>
    </Button>
    <Button
      variant={buttonVariant}
      className="c-autocomplete--multi__selected p-1"
      aria-label={locale('core.article_form_co_author_invitation_remove', {
        name: fullName,
      })}
      onClick={onDeselect}
    >
      <Icon src={Close} />
    </Button>
  </div>
);

/**
 * Lets an author invite their followers to co-author a personal post. Invitations are sent when
 * the post is saved, and each person is credited once they accept from their notifications.
 *
 * @param {Object} props
 * @param {Array} props.invitees Users currently selected as co-authors
 * @param {Array} props.invitations The post's saved invitations, used for their statuses
 * @param {number} props.maxSelections Maximum number of co-authors
 * @param {Function} props.onConfigChange Callback to sync selections into editor state
 */
export const CoAuthorInvitationSelector = ({
  invitees,
  invitations,
  maxSelections,
  onConfigChange,
}) => {
  const statusesByUserId = useMemo(
    () =>
      Object.fromEntries(
        invitations.map(({ user, status }) => [user.id, status]),
      ),
    [invitations],
  );

  const declinedUsers = useMemo(
    () =>
      invitations
        .filter(({ status }) => status === 'declined')
        .map(({ user }) => user),
    [invitations],
  );

  const selectedOptions = useMemo(
    () => invitees.map((user) => toOption(user, statusesByUserId[user.id])),
    [invitees, statusesByUserId],
  );

  const fetchSuggestions = async (term) => {
    try {
      const response = await window.fetch(
        `${CANDIDATES_PATH}?search=${encodeURIComponent(term)}`,
        {
          headers: { Accept: 'application/json' },
          credentials: 'same-origin',
        },
      );
      if (!response.ok) {
        return [];
      }

      const users = await response.json();
      // People who declined can't be invited to this post again.
      return users
        .filter((user) => statusesByUserId[user.id] !== 'declined')
        .map((user) => toOption(user, statusesByUserId[user.id]));
    } catch (error) {
      Honeybadger.notify(error);
      return [];
    }
  };

  return (
    <div className="crayons-field mb-6">
      <label
        htmlFor="article-co-author-invitations"
        className="crayons-field__label"
      >
        {locale('core.article_form_co_authors')}
      </label>
      <p className="crayons-field__description mb-4">
        {locale('core.article_form_co_author_invitations_description')}
      </p>
      <MultiSelectAutocomplete
        labelText={locale('core.article_form_co_authors')}
        showLabel={false}
        placeholder={locale(
          'core.article_form_co_author_invitations_placeholder',
        )}
        inputId="article-co-author-invitations"
        maxSelections={maxSelections}
        defaultValue={selectedOptions}
        fetchSuggestions={fetchSuggestions}
        SuggestionTemplate={CandidateSuggestion}
        SelectionTemplate={InviteeSelection}
        onSelectionsChanged={(selections) =>
          onConfigChange({
            target: { name: 'coAuthorInvitees', value: selections.map(toUser) },
            preventDefault: () => {},
            stopPropagation: () => {},
          })
        }
      />
      {declinedUsers.length > 0 && (
        <p className="crayons-field__description mt-2">
          {locale('core.article_form_co_author_invitations_declined', {
            names: declinedUsers.map(({ name }) => name).join(', '),
          })}
        </p>
      )}
    </div>
  );
};

const userShape = PropTypes.shape({
  id: PropTypes.number.isRequired,
  name: PropTypes.string,
  username: PropTypes.string.isRequired,
  profile_image_90: PropTypes.string,
});

CoAuthorInvitationSelector.propTypes = {
  invitees: PropTypes.arrayOf(userShape).isRequired,
  invitations: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number.isRequired,
      status: PropTypes.oneOf(['pending', 'accepted', 'declined']).isRequired,
      user: userShape.isRequired,
    }),
  ).isRequired,
  maxSelections: PropTypes.number.isRequired,
  onConfigChange: PropTypes.func.isRequired,
};
