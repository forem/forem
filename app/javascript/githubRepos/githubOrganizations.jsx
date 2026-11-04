import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { ButtonNew as Button } from '@crayons';
import { request } from '@utilities/http';

/**
 * Lets the user register the GitHub organizations whose public repositories
 * they can pin, e.g. after transferring a repository to an organization.
 */
export const GithubOrganizations = ({
  initialOrganizations,
  maxOrganizations,
  onChange,
}) => {
  const [organizations, setOrganizations] = useState(initialOrganizations);
  const [name, setName] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const limitReached = organizations.length >= maxOrganizations;

  // Sends the request and, on success, stores the organizations returned by the
  // server and asks the parent to reload the list of repositories.
  const submit = async (url, options) => {
    setBusy(true);
    setError('');

    try {
      const response = await request(url, options);
      const body = await response.json();

      if (!response.ok) {
        setError(body.error);
        return false;
      }

      setOrganizations(body.organizations);
      await onChange();
      return true;
    } catch (_) {
      setError('Something went wrong, please try again.');
      return false;
    } finally {
      setBusy(false);
    }
  };

  const addOrganization = async (event) => {
    event.preventDefault();

    const added = await submit('/github_organizations', {
      method: 'POST',
      body: { organization: name },
    });
    if (added) {
      setName('');
    }
  };

  const removeOrganization = (organization) =>
    submit(`/github_organizations/${encodeURIComponent(organization)}`, {
      method: 'DELETE',
    });

  return (
    <div className="github-organizations" data-testid="github-organizations">
      <ul className="list-none p-0">
        {organizations.map((organization) => (
          <li key={organization} className="flex items-center mb-2">
            <span className="mr-2">{organization}</span>
            <Button
              size="s"
              aria-label={`Remove ${organization}`}
              disabled={busy}
              onClick={() => removeOrganization(organization)}
            >
              ×
            </Button>
          </li>
        ))}
      </ul>

      <form className="flex items-center" onSubmit={addOrganization}>
        <label htmlFor="github-organization-name" className="screen-reader-only">
          Organization username
        </label>
        <input
          id="github-organization-name"
          className="crayons-textfield mr-2"
          type="text"
          placeholder="Organization username"
          value={name}
          disabled={busy || limitReached}
          onInput={(event) => setName(event.target.value)}
        />
        <Button
          type="submit"
          variant="secondary"
          disabled={busy || limitReached || name.trim() === ''}
        >
          Add
        </Button>
      </form>

      <p className="color-base-70 fs-s mt-2">
        {organizations.length} / {maxOrganizations} organizations
      </p>

      {error && (
        <p className="color-accent-danger" role="alert">
          {error}
        </p>
      )}
    </div>
  );
};

GithubOrganizations.propTypes = {
  initialOrganizations: PropTypes.arrayOf(PropTypes.string),
  maxOrganizations: PropTypes.number,
  onChange: PropTypes.func.isRequired,
};

GithubOrganizations.defaultProps = {
  initialOrganizations: [],
  maxOrganizations: 3,
};

GithubOrganizations.displayName = 'GitHub Organizations';
