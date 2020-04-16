import { h } from 'preact';
import render from 'preact-render-to-json';
import { deep } from 'preact-render-spy';
import {
  CommentSubscription,
  COMMENT_SUBSCRIPTION_TYPE,
} from '../CommentSubscription';

describe('<CommentSubscription />', () => {
  it('should render as a plain subscribe button if not currently subscribed', () => {
    const tree = render(<CommentSubscription />);

    expect(tree).toMatchSnapshot();
  });

  it('should render as subscribed with the given subscription type', () => {
    const tree = render(
      <CommentSubscription
        subscriptionType={COMMENT_SUBSCRIPTION_TYPE.AUTHOR}
      />,
    );

    expect(tree).toMatchSnapshot();
  });

  it('should subscribe when the subscribe button is pressed', () => {
    const onSubscribe = jest.fn();
    const wrapper = deep(<CommentSubscription onSubscribe={onSubscribe} />);
    wrapper.find('ButtonGroup').find('Button').first().simulate('click');

    expect(onSubscribe).toHaveBeenCalled();
  });

  it('should unsubscribe from all comments when the Unsubscribe button is pressed', () => {
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

  it('should show subscription options once subscribed if the cog button is clicked', () => {
    const onSubscribe = jest.fn();
    const onUnsubscribe = jest.fn();
    const wrapper = deep(
      <CommentSubscription
        subscriptionType={COMMENT_SUBSCRIPTION_TYPE.AUTHOR}
        onSubscribe={onSubscribe}
        onUnsubscribe={onUnsubscribe}
      />,
    );

    wrapper.find('ButtonGroup').find('Button').last().simulate('click'); // Cog icon button

    const dropdown = wrapper.find('Dropdown');
    expect(dropdown.attr('className')).toEqual(
      'inline-block z-10 right-4 left-4 s:right-0 s:left-auto w-full',
    );

    // 3 options for comment subscription
    expect(dropdown.find('RadioButton').length).toEqual(3);

    // The done button
    expect(dropdown.find('Button').length).toEqual(1);
  });

  it('should not have full width for options when positionType is anything but "relative"', () => {
    const onSubscribe = jest.fn();
    const onUnsubscribe = jest.fn();
    const wrapper = deep(
      <CommentSubscription
        onSubscribe={onSubscribe}
        onUnsubscribe={onUnsubscribe}
        positionType="static"
        subscriptionType={COMMENT_SUBSCRIPTION_TYPE.AUTHOR}
      />,
    );

    wrapper.find('ButtonGroup').find('Button').last().simulate('click'); // Cog icon button to open subscription options panel

    expect(wrapper.find('Dropdown').attr('className')).toEqual(
      'inline-block z-10 right-4 left-4 s:right-0 s:left-auto',
    );
  });

  it('should hide subscription options when the Done button is clicked', () => {
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
    const onSubscribe = jest.fn();
    const onUnsubscribe = jest.fn();

    const wrapper = deep(
      <CommentSubscription
        subscriptionType={COMMENT_SUBSCRIPTION_TYPE.TOP}
        onSubscribe={onSubscribe}
        onUnsubscribe={onUnsubscribe}
      />,
    );

    wrapper.find('ButtonGroup').find('button').first().simulate('click'); // Subscribe button

    expect(wrapper.state('subscriptionType')).toEqual(
      COMMENT_SUBSCRIPTION_TYPE.TOP,
    );

    wrapper.find('ButtonGroup').find('Button').last().simulate('click'); // Cog icon button

    const dropdown = wrapper.find('Dropdown');

    // Select the author comments only.
    const authorCommentsOnlyRadioButton = dropdown.find('RadioButton').last();
    expect(authorCommentsOnlyRadioButton.attr('value')).toEqual(
      COMMENT_SUBSCRIPTION_TYPE.AUTHOR,
    );
    authorCommentsOnlyRadioButton.simulate('click', {
      target: { value: COMMENT_SUBSCRIPTION_TYPE.AUTHOR },
    });

    const done = dropdown.find('Button');
    done.simulate('click');

    expect(wrapper.state('subscriptionType')).toEqual(
      COMMENT_SUBSCRIPTION_TYPE.AUTHOR,
    );

    // a second time by clicking on the Done button.
    expect(onSubscribe).toHaveBeenCalled();
  });
});
