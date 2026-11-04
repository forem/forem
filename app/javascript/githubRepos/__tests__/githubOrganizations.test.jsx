import { h } from 'preact';
import { render, screen, waitFor } from '@testing-library/preact';
import userEvent from '@testing-library/user-event';
import fetch from 'jest-fetch-mock';
import { GithubOrganizations } from '../githubOrganizations';

global.fetch = fetch;
jest.mock('../../utilities/http/csrfToken', () => ({
  getCSRFToken: jest.fn(() => Promise.resolve('csrf-token')),
}));

describe('<GithubOrganizations />', () => {
  beforeEach(() => fetch.resetMocks());

  it('lists the organizations and how many are used', () => {
    render(
      <GithubOrganizations
        initialOrganizations={['necoz-oss']}
        maxOrganizations={3}
        onChange={jest.fn()}
      />,
    );

    expect(screen.getByText('necoz-oss')).toBeInTheDocument();
    expect(screen.getByText('1 / 3 organizations')).toBeInTheDocument();
  });

  it('adds an organization and notifies the parent', async () => {
    fetch.mockResponseOnce(JSON.stringify({ organizations: ['necoz-oss'] }), {
      status: 201,
    });
    const onChange = jest.fn();
    render(<GithubOrganizations maxOrganizations={3} onChange={onChange} />);

    await userEvent.type(
      screen.getByLabelText('Organization username'),
      'necoz-oss',
    );
    await userEvent.click(screen.getByRole('button', { name: 'Add' }));

    await waitFor(() => expect(onChange).toHaveBeenCalled());
    expect(screen.getByText('necoz-oss')).toBeInTheDocument();
    expect(fetch.mock.calls[0][0]).toBe('/github_organizations');
  });

  it('shows the error returned by the server', async () => {
    fetch.mockResponseOnce(JSON.stringify({ error: 'GitHub organization not found' }), {
      status: 404,
    });
    const onChange = jest.fn();
    render(<GithubOrganizations maxOrganizations={3} onChange={onChange} />);

    await userEvent.type(screen.getByLabelText('Organization username'), 'nope');
    await userEvent.click(screen.getByRole('button', { name: 'Add' }));

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'GitHub organization not found',
    );
    expect(onChange).not.toHaveBeenCalled();
  });

  it('removes an organization', async () => {
    fetch.mockResponseOnce(JSON.stringify({ organizations: [] }));
    const onChange = jest.fn();
    render(
      <GithubOrganizations
        initialOrganizations={['necoz-oss']}
        maxOrganizations={3}
        onChange={onChange}
      />,
    );

    await userEvent.click(
      screen.getByRole('button', { name: 'Remove necoz-oss' }),
    );

    await waitFor(() => expect(onChange).toHaveBeenCalled());
    expect(screen.queryByText('necoz-oss')).not.toBeInTheDocument();
    expect(fetch.mock.calls[0][0]).toBe('/github_organizations/necoz-oss');
  });

  it('disables adding once the limit is reached', () => {
    render(
      <GithubOrganizations
        initialOrganizations={['a', 'b', 'c']}
        maxOrganizations={3}
        onChange={jest.fn()}
      />,
    );

    expect(screen.getByLabelText('Organization username')).toBeDisabled();
    expect(screen.getByRole('button', { name: 'Add' })).toBeDisabled();
  });
});
