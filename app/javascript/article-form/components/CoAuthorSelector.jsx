import { h } from 'preact';
import PropTypes from 'prop-types';
import { useEffect, useMemo, useState } from 'preact/hooks';
import { UsernameInput } from '@components/UsernameInput';
import { UserStore } from '@components/UserStore';
import { locale } from '@utilities/locale';

export const CoAuthorSelector = ({
  authorId,
  coAuthorIdsList,
  organizationId,
  organizations,
  onConfigChange,
}) => {
  const [users, setUsers] = useState(null);
  const selectedOrganization = useMemo(
    () =>
      organizations.find(
        (organization) => String(organization.id) === String(organizationId),
      ),
    [organizationId, organizations],
  );
  const canManageCoAuthors = Boolean(
    selectedOrganization?.can_add_co_authors &&
      selectedOrganization?.fetch_users_url,
  );

  useEffect(() => {
    let canceled = false;

    if (!canManageCoAuthors) {
      setUsers(null);
      return undefined;
    }

    setUsers(null);
    UserStore.fetch(selectedOrganization.fetch_users_url).then((fetchedUsers) => {
      if (!canceled) {
        setUsers(fetchedUsers || new UserStore());
      }
    });

    return () => {
      canceled = true;
    };
  }, [canManageCoAuthors, selectedOrganization]);

  if (!canManageCoAuthors || !users) {
    return null;
  }

  const selectedIds = coAuthorIdsList
    .split(',')
    .map((id) => id.trim())
    .filter(Boolean);
  const defaultValue = users.matchingIds(selectedIds);

  return (
    <div className="crayons-field mb-6">
      <label htmlFor="article-co-author-ids-list" className="crayons-field__label">
        {locale('core.article_form_co_authors')}
      </label>
      <p className="crayons-field__description mb-4">
        {locale('core.article_form_co_authors_description', {
          org_name: selectedOrganization?.name || 'the selected organization',
        })}
      </p>
      <UsernameInput
        labelText={locale('core.article_form_co_authors')}
        placeholder={locale('core.article_form_co_authors_placeholder')}
        maxSelections={4}
        inputId="article-co-author-ids-list"
        defaultValue={defaultValue}
        fetchSuggestions={(term) => users.search(term, { except: authorId })}
        handleSelectionsChanged={(ids) => {
          onConfigChange({
            target: {
              name: 'coAuthorIdsList',
              value: ids,
            },
            preventDefault: () => {},
            stopPropagation: () => {},
          });
          onConfigChange({
            target: {
              name: 'coAuthorsData',
              value: users.matchingIds(ids.split(',').map((i) => i.trim()).filter(Boolean)),
            },
            preventDefault: () => {},
            stopPropagation: () => {},
          });
        }}
      />
    </div>
  );
};

CoAuthorSelector.propTypes = {
  authorId: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  coAuthorIdsList: PropTypes.string,
  organizationId: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  organizations: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.oneOfType([PropTypes.number, PropTypes.string]).isRequired,
      can_add_co_authors: PropTypes.bool,
      fetch_users_url: PropTypes.string,
    }),
  ).isRequired,
  onConfigChange: PropTypes.func.isRequired,
};

CoAuthorSelector.defaultProps = {
  authorId: null,
  coAuthorIdsList: '',
  organizationId: null,
};
