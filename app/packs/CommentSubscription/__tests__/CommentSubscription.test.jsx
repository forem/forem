import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import '@testing-library/jest-dom';
import { axe } from 'jest-axe';
import {
  CommentSubscription,
  COMMENT_SUBSCRIPTION_TYPE,
} from '../CommentSubscription';

describe('<CommentSubscription />', () => {
  it('should have no a11y violations when not subscribed', async () => {
    const { container } = render(<CommentSubscription />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations when subscribed', async () => {
    const { container } = render(
      <CommentSubscription
        subscriptionType={COMMENT_SUBSCRIPTION_TYPE.AUTHOR}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render as a plain subscribe button if not currently subscribed', () => {
    const { getByText } = render(<CommentSubscription />);
    const button = getByText(/subscribe/i, { selector: 'button' });

    expect(button).not.toBeNull();
  });

  it('should render as subscribed with the given subscription type', () => {
    const { getByTestId, getByText, getByLabelText } = render(
      <CommentSubscription
        subscriptionType={COMMENT_SUBSCRIPTION_TYPE.AUTHOR}
      />,
    );
    const button = getByText(/unsubscribe/i, { selector: 'button' });
    expect(button).not.toBeNull();

    const cogButton = getByTestId('subscription-settings');
    cogButton.click();

    const onlyAuthorCommentsRadioButton = getByLabelText(
      /^Post author comments/i,
    );

    expect(onlyAuthorCommentsRadioButton.checked).toEqual(true);
  });

  it('should subscribe when the subscribe button is pressed', () => {
    const onSubscribe = jest.fn();
    const { getByText } = render(
      <CommentSubscription onSubscribe={onSubscribe} isLoggedIn={true} />,
    );

    const button = getByText(/subscribe/i, { selector: 'button' });
    button.click();

    expect(onSubscribe).toHaveBeenCalled();
  });

  it('should unsubscribe from all comments when the Unsubscribe button is pressed', async () => {
    const onUnsubscribe = jest.fn();
    const { getByText } = render(
      <CommentSubscription
        subscriptionType={COMMENT_SUBSCRIPTION_TYPE.AUTHOR}
        onUnsubscribe={onUnsubscribe}
        isLoggedIn={true}
      />,
    );

    const unsubscribeButton = getByText(/unsubscribe/i, { selector: 'button' });
    unsubscribeButton.click();

    expect(onUnsubscribe).toHaveBeenCalled();
  });

  it('should update comment subscription when the done button is clicked in the subscription options panel', async () => {
    const onSubscribe = jest.fn();

    const { getByTestId, getByText, getByLabelText } = render(
      <CommentSubscription
        subscriptionType={COMMENT_SUBSCRIPTION_TYPE.ALL}
        onSubscribe={onSubscribe}
      />,
    );

    const cogButton = getByTestId('subscription-settings');
    cogButton.click();

    const onlyAuthorCommentsRadioButton = getByLabelText(
      /^Post author comments/i,
    );
    onlyAuthorCommentsRadioButton.click();
    expect(onlyAuthorCommentsRadioButton).toBeChecked();

    const doneButton = getByText(/done/i);
    doneButton.click();

    waitFor(() =>
      expect(onSubscribe).toHaveBeenCalledWith(
        COMMENT_SUBSCRIPTION_TYPE.AUTHOR,
      ),
    );
  });
});
