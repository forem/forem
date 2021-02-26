import { h } from 'preact';
import { render } from '@testing-library/preact';
import '@testing-library/jest-dom';
import { axe } from 'jest-axe';
import { Message } from '../message';

const msg = {
  username: 'asdf',
  used_id: 12345,
  message: 'WE BUILT THIS CITY',
  color: '#00FFFF',
};

const getMessage = (message, props) => (
  <Message
    user={message.username}
    userID={message.user_id}
    message={message.message}
    color={message.color}
    {...props}
  />
);

describe('<Message />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(getMessage(msg));
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render', () => {
    const { getByText, getByAltText } = render(getMessage(msg));

    getByAltText('asdf profile');
    getByText(msg.message);

    const profileLink = getByText(msg.username);

    expect(profileLink.parentElement).toHaveStyle({ color: msg.color });
  });

  it('should highlight @mentions to the logged in user', () => {
    const testMessage = {
      username: 'testUser',
      user_id: 456,
      message: "<p>hello <a href='testUser'>@testUser</a></p>",
    };

    const { getByText } = render(
      getMessage(testMessage, { currentUserId: testMessage.user_id }),
    );

    const profileLink = getByText(`@${testMessage.username}`);

    expect(profileLink.parentElement.innerHTML).toMatch(
      new RegExp(`<mark>@${testMessage.username}</mark>`, 'i'),
    );
  });
});
