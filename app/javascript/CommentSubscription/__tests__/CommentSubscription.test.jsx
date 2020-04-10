import { h } from 'preact';
import render from 'preact-render-to-json';
import { deep } from 'preact-render-spy';
import { CommentSubscription } from '../CommentSubscription';

describe('<CommentSubscription />', () => {
  it('should render as a plain subscribe button if not currently subscribed', () => {
    const tree = render(<CommentSubscription />);

    expect(tree).toMatchSnapshot();
  });

  it('should subscribe to all comments by default', () => {
    const onSubscribe = jest.fn();
    const wrapper = deep(<CommentSubscription onSubscribe={onSubscribe} />);
    wrapper.find('ButtonGroup').find('Button').first().simulate('click');

    expect(onSubscribe).toHaveBeenCalled();
  });

  it('should unsubscribe from all comments', () => {
    const onSubscribe = jest.fn();
    const onUnsubscribe = jest.fn();
    const wrapper = deep(
      <CommentSubscription
        onSubscribe={onSubscribe}
        onUnsubscribe={onUnsubscribe}
      />,
    );

    // Need to subscribe first so that we can unsubscribe.
    wrapper.find('ButtonGroup').find('Button').first().simulate('click'); // Subscribe button
    wrapper.find('ButtonGroup').find('Button').first().simulate('click'); // Unsubscribe button

    expect(onUnsubscribe).toHaveBeenCalled();
  });

  it('should show subscription options once subscribed if cog icon is clicked', () => {
    const onSubscribe = jest.fn();
    const onUnsubscribe = jest.fn();
    const wrapper = deep(
      <CommentSubscription
        onSubscribe={onSubscribe}
        onUnsubscribe={onUnsubscribe}
      />,
    );

    wrapper.find('ButtonGroup').find('Button').first().simulate('click'); // Subscribe button
    wrapper.find('ButtonGroup').find('Button').last().simulate('click'); // Cog icon button

    const dropdown = wrapper.find('Dropdown');
    expect(dropdown.attr('className')).toEqual(
      'inline-block w-full z-10 right-0',
    );

    // 3 options for comment subscription
    expect(dropdown.find('RadioButton').length).toEqual(3);

    // The done button
    expect(dropdown.find('Button').length).toEqual(1);
  });

  it('should hide subscription options once subscribed if cog icon is clicked and the subscriptions options panel is open', () => {
    const onSubscribe = jest.fn();
    const onUnsubscribe = jest.fn();
    const wrapper = deep(
      <CommentSubscription
        onSubscribe={onSubscribe}
        onUnsubscribe={onUnsubscribe}
      />,
    );

    wrapper.find('ButtonGroup').find('Button').first().simulate('click'); // Subscribe button
    wrapper.find('ButtonGroup').find('Button').last().simulate('click'); // Cog icon button to open subscription options panel
    wrapper.find('ButtonGroup').find('Button').last().simulate('click'); // Cog icon button to close subscription options panel

    const dropdown = wrapper.find('Dropdown');
    expect(dropdown.attr('className')).toBeNull();
  });

  it('should update comment subscription when the done button is clicked in the subscription options panel', () => {
    let commentType;

    const onSubscribe = jest.fn((commentSubscriptionType) => {
      commentType = commentSubscriptionType;
    });
    const onUnsubscribe = jest.fn();
    const ONLY_AUTHOR_COMMENTS = 'only_author_comments';
    const wrapper = deep(
      <CommentSubscription
        onSubscribe={onSubscribe}
        onUnsubscribe={onUnsubscribe}
      />,
    );

    wrapper.find('ButtonGroup').find('button').first().simulate('click'); // Subscribe button

    expect(commentType).toEqual('all_comments');

    wrapper.find('ButtonGroup').find('Button').last().simulate('click'); // Cog icon button

    const dropdown = wrapper.find('Dropdown');

    // Select the author comments only.
    const authorCommentsOnlyRadioButton = dropdown.find('RadioButton').last();
    expect(authorCommentsOnlyRadioButton.attr('value')).toEqual(
      ONLY_AUTHOR_COMMENTS,
    );
    authorCommentsOnlyRadioButton.simulate('click', {
      target: { value: ONLY_AUTHOR_COMMENTS },
    });

    const done = dropdown.find('Button');
    done.simulate('click');

    expect(commentType).toEqual(ONLY_AUTHOR_COMMENTS);

    // Called once by the initial subscribe and
    // a second time by clicking on the Done button.
    expect(onSubscribe).toHaveBeenCalledTimes(2);
  });
});
