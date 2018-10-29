import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import Message from '../message';

const msg = {
  username: 'asdf',
  used_id: 12345,
  message: 'WE BUILT THIS CITY',
  color: '#00FFFF',
};

const getMessage = message => (
  <Message
    user={message.username}
    userID={message.user_id}
    message={message.message}
    color={message.color}
  />
);

describe('<Message />', () => {
  it('should render and test snapshot', () => {
    const tree = render(getMessage(msg));
    expect(tree).toMatchSnapshot();
  });

  it('should have the proper elements, attributes and values', () => {
    const context = shallow(getMessage(msg));
    expect(context.find('.chatmessage').exists()).toEqual(true);
    expect(
      context.find('.chatmessagebody__message').attr('dangerouslySetInnerHTML'),
    ).toEqual({ __html: msg.message });
    expect(
      context.find('.chatmessagebody__username').attr('style').color,
    ).toEqual(msg.color);
    expect(context.find('.chatmessagebody__username--link').text()).toEqual(
      msg.username,
    );
  });
});
