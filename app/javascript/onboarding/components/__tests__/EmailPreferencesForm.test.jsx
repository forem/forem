import { h } from 'preact';
import { render } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import { axe } from 'jest-axe';

import { EmailPreferencesForm } from '../EmailPreferencesForm';

global.fetch = fetch;

describe('EmailPreferencesForm', () => {
  const renderEmailPreferencesForm = () =>
    render(
      <EmailPreferencesForm
        next={jest.fn()}
        prev={jest.fn()}
        currentSlideIndex={4}
        slidesCount={5}
        communityConfig={{
          communityName: 'Community Name',
          communityLogo: '/x.png',
          communityBackgroundColor: '#FFF000',
          communityDescription: 'Some community description',
        }}
        previousLocation={null}
      />,
    );

  const getUserData = () =>
    JSON.stringify({
      followed_tag_names: ['javascript'],
      profile_image_90: 'mock_url_link',
      name: 'firstname lastname',
      username: 'username',
    });

  const fakeResponse = JSON.stringify({
    content: `
    <h1>Almost there!</h1>
    <form>
      <fieldset>
        <ul>
          <li class="checkbox-item">
            <label for="email_newsletter"><input type="checkbox" id="email_newsletter" name="email_newsletter">I want to receive weekly newsletter emails.</label>
          </li>
        </ul>
      </fieldset>
    </form>
    `,
  });

  beforeEach(() => {
    fetch.resetMocks();
    fetch.mockResponseOnce(fakeResponse);
  });

  beforeAll(() => {
    document.head.innerHTML =
      '<meta name="csrf-token" content="some-csrf-token" />';
    document.body.setAttribute('data-user', getUserData());
  });

  it('should have no a11y violations', async () => {
    const { container } = render(renderEmailPreferencesForm());
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should load the appropriate text', async () => {
    const { findByLabelText } = renderEmailPreferencesForm();
    await findByLabelText(/receive weekly newsletter/i);
    expect(document.body.innerHTML).toMatchSnapshot();
  });

  it('should show the checkbox unchecked', async () => {
    const { findByLabelText } = renderEmailPreferencesForm();
    const checkbox = await findByLabelText(/receive weekly newsletter/i);
    expect(checkbox.checked).toBe(false);
  });

  it('should render a stepper', () => {
    const { queryByTestId } = renderEmailPreferencesForm();

    expect(queryByTestId('stepper')).toExist();
  });

  it('should render a back button', () => {
    const { queryByTestId } = renderEmailPreferencesForm();

    expect(queryByTestId('back-button')).toExist();
  });

  it('should render a button that says Finish', () => {
    const { queryByText } = renderEmailPreferencesForm();

    expect(queryByText('Finish')).toExist();
  });
});
