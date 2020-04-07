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
    wrapper.find('button').simulate('click');

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
    wrapper.find('button').first().simulate('click'); // Subscribe button

    wrapper.find('button').first().simulate('click'); // Unsubscribe button

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

    // Need to subscribe first so that we can unsubscribe.
    wrapper.find('button').first().simulate('click'); // Subscribe button

    wrapper.find('button:last-child').simulate('click'); // Cog icon button

    const dropdown = wrapper.find('Dropdown');

    expect(dropdown.length).toEqual(1);
    expect(dropdown.find('RadioButton').length).toEqual(3);
    expect(dropdown.find('Button').length).toEqual(1);
  });

  it('should update comment subscription when the done button is clicked in the subscription options panel', () => {
    const onSubscribe = jest.fn();
    const onUnsubscribe = jest.fn();
    const wrapper = deep(
      <CommentSubscription
        onSubscribe={onSubscribe}
        onUnsubscribe={onUnsubscribe}
      />,
    );

    // Need to subscribe first so that we can unsubscribe.
    wrapper.find('button').first().simulate('click'); // Subscribe button

    wrapper.find('button:last-child').simulate('click'); // Cog icon button

    const done = wrapper.find('Dropdown').find('Button');

    done.simulate('click');

    // Called once by the initial subscribe and
    // a second time by clicking on the Done button.
    expect(onSubscribe).toHaveBeenCalledTimes(2);
  });
});
