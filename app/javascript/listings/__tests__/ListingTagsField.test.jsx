import fetch from 'jest-fetch-mock';
import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';
import { ListingTagsField } from '../components/ListingTagsField';
import '@testing-library/jest-dom';

fetch.enableMocks();

let renderResult;
const csrfToken = 'this-is-a-csrf-token';
jest.mock('../../utilities/http/csrfToken', () => ({
  getCSRFToken: jest.fn(() => Promise.resolve(csrfToken)),
}));

describe('<ListingTagsField />', () => {
  beforeAll(() => {
    const environment = document.createElement('meta');
    environment.setAttribute('name', 'environment');
    document.body.appendChild(environment);
    fetch.resetMocks();
    window.fetch = fetch;
    fetch.mockResponse((_req) =>
      Promise.resolve(JSON.stringify({ result: [] })),
    );
  });

  beforeEach(() => {
    renderResult = render(
      <ListingTagsField
        defaultValue="tag1, tag2"
        categorySlug="jobs"
        name="listing[tag_list]"
        onInput={(_) => {}}
      />,
    );
  });

  afterAll(() => {
    fetch.resetMocks();
  });

  it('should have no a11y violations', async () => {
    const { container } = renderResult;
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should show additional tags suggestions depending on the selected category', async () => {
    const { getByLabelText, getByText, getByRole } = renderResult;
    getByLabelText('Tags').focus();
    await waitFor(() => expect(getByText('Top tags')).toBeInTheDocument());

    // Additional tags for jobs category are expected to be shown in the dropdown
    // when the user focuses on the tags input.
    const tagsForJobsCategory = [
      'remote',
      'remoteoptional',
      'lgbtbenefits',
      'greencard',
      'senior',
      'junior',
      'intermediate',
      '401k',
      'fulltime',
      'contract',
      'temp',
    ];
    tagsForJobsCategory.forEach((tag) => {
      expect(getByRole('option', { name: `# ${tag}` })).toBeInTheDocument();
    });
  });

  it('should show the default tags sent via props', async () => {
    const { getByRole } = renderResult;
    await waitFor(() => {
      expect(getByRole('group', { name: 'tag1' })).toBeInTheDocument();
      expect(getByRole('group', { name: 'tag2' })).toBeInTheDocument();
    });
  });

  it('should show new selected tags', async () => {
    const { getByLabelText, getByRole } = renderResult;

    // New selected tags are expected to be shown
    const input = getByLabelText('Tags');
    input.focus();

    // Make sure default state has loaded
    await waitFor(() =>
      expect(getByRole('group', { name: 'tag1' })).toBeInTheDocument(),
    );

    await waitFor(() =>
      expect(getByRole('option', { name: '# remote' })).toBeInTheDocument(),
    );

    userEvent.click(getByRole('option', { name: '# remote' }));

    // It should now be added to the list of selected items

    await waitFor(() =>
      expect(getByRole('group', { name: 'remote' })).toBeInTheDocument(),
    );
  });

  it('should suggest tags based on the input value', async () => {
    const { getByLabelText, getByText, getByRole } = renderResult;

    const input = getByLabelText('Tags');
    input.focus();

    await waitFor(() => expect(getByText('Top tags')).toBeInTheDocument());

    userEvent.type(input, 're');

    // Should suggest tags that start with 're'
    // - remote
    // - remoteoptional
    await waitFor(() => {
      expect(getByRole('option', { name: '# remote' })).toBeInTheDocument();
      expect(
        getByRole('option', { name: '# remoteoptional' }),
      ).toBeInTheDocument();
    });
  });
});
