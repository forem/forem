/* global showLoginModal */

import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import {
  Button,
  ButtonGroup,
  Dropdown,
  FormField,
  RadioButton,
} from '@crayons';

export const COMMENT_SUBSCRIPTION_TYPE = Object.freeze({
  ALL: 'all_comments',
  TOP: 'top_level_comments',
  AUTHOR: 'only_author_comments',
  NOT_SUBSCRIBED: 'not_subscribed',
});

export class CommentSubscription extends Component {
  constructor(props) {
    const { subscriptionType } = props;
    super(props);

    const subscribed =
      subscriptionType &&
      (subscriptionType.length > 0 && subscriptionType) !==
        COMMENT_SUBSCRIPTION_TYPE.NOT_SUBSCRIBED;

    const initialState = {
      subscriptionType: subscribed
        ? subscriptionType
        : COMMENT_SUBSCRIPTION_TYPE.ALL,
      subscribed,
      showOptions: false,
    };

    this.state = initialState;
  }

  componentDidUpdate() {
    const { showOptions } = this.state;

    if (showOptions) {
      window.addEventListener('scroll', this.dropdownPlacementHandler);
      this.dropdownPlacementHandler();
    } else {
      window.removeEventListener('scroll', this.dropdownPlacementHandler);
    }
  }

  componentWillUnmount() {
    window.removeEventListener('scroll', this.dropdownPlacementHandler);
  }

  dropdownPlacementHandler = () => {
    const { base: element } = this.dropdownElement;

    // Reset the top before doing any calculations
    element.style.bottom = '';

    const { bottom: dropDownBottom } = element.getBoundingClientRect();
    const { height } = this.buttonGroupElement.base.getBoundingClientRect();

    if (
      Math.sign(dropDownBottom) === -1 ||
      dropDownBottom > window.innerHeight
    ) {
      // The 4 pixels is the box shadow from the drop down.
      element.style.bottom = `${height + 4}px`;
    }
  };

  commentSubscriptionClick = (event) => {
    this.setState({
      subscriptionType: event.target.value,
    });
  };

  render() {
    const { showOptions, subscriptionType, subscribed } = this.state;
    const {
      onSubscribe,
      onUnsubscribe,
      positionType = 'relative',
      isLoggedIn
    } = this.props;

    const CogIcon = () => (
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="24"
        height="24"
        role="img"
        aria-labelledby="ai2ols8ka2ohfp0z568lj68ic2du21s"
        className="crayons-icon"
      >
        <title id="ai2ols8ka2ohfp0z568lj68ic2du21s">Preferences</title>
        <path d="M12 1l9.5 5.5v11L12 23l-9.5-5.5v-11L12 1zm0 2.311L4.5 7.653v8.694l7.5 4.342 7.5-4.342V7.653L12 3.311zM12 16a4 4 0 110-8 4 4 0 010 8zm0-2a2 2 0 100-4 2 2 0 000 4z" />
      </svg>
    );

    return (
      <div className={positionType}>
        <ButtonGroup
          ref={(element) => {
            this.buttonGroupElement = element;
          }}
        >
          <Button
            variant="outlined"
            onClick={(_event) => {
              if (isLoggedIn) {
                if (subscribed) {
                  onUnsubscribe(COMMENT_SUBSCRIPTION_TYPE.NOT_SUBSCRIBED);
                  this.setState({
                    subscriptionType: COMMENT_SUBSCRIPTION_TYPE.ALL,
                  });
                } else {
                  onSubscribe(subscriptionType);
                }

                this.setState({ subscribed: !subscribed });
              } else {
                showLoginModal();
              }
            }}
          >
            {subscribed ? 'Unsubscribe' : 'Subscribe'}
          </Button>
          {subscribed && (
            <Button
              data-testid="subscription-settings"
              variant="outlined"
              icon={CogIcon}
              contentType="icon"
              onClick={(_event) => {
                this.setState({ showOptions: !showOptions });
              }}
            />
          )}
        </ButtonGroup>
        {subscribed && (
          <Dropdown
            data-testid="subscriptions-panel"
            aria-hidden={!showOptions}
            className={
              showOptions
                ? `inline-block right-4 left-4 s:right-0 s:left-auto${
                    positionType === 'relative' ? ' w-full' : ''
                  }`
                : null
            }
            ref={(element) => {
              this.dropdownElement = element;
            }}
          >
            <div className="crayons-fields mb-5">
              <FormField variant="radio">
                <RadioButton
                  id="subscribe-all"
                  name="subscribe_comments"
                  value={COMMENT_SUBSCRIPTION_TYPE.ALL}
                  checked={subscriptionType === COMMENT_SUBSCRIPTION_TYPE.ALL}
                  onClick={this.commentSubscriptionClick}
                />
                <label htmlFor="subscribe-all" className="crayons-field__label">
                  All comments
                  <p className="crayons-field__description">
                    You’ll receive notifications for all new comments.
                  </p>
                </label>
              </FormField>

              <FormField variant="radio">
                <RadioButton
                  id="subscribe-toplevel"
                  name="subscribe_comments"
                  value={COMMENT_SUBSCRIPTION_TYPE.TOP}
                  onClick={this.commentSubscriptionClick}
                  checked={subscriptionType === COMMENT_SUBSCRIPTION_TYPE.TOP}
                />
                <label
                  htmlFor="subscribe-toplevel"
                  className="crayons-field__label"
                >
                  Top-level comments
                  <p className="crayons-field__description">
                    You’ll receive notifications only for all new top-level
                    comments.
                  </p>
                </label>
              </FormField>

              <FormField variant="radio">
                <RadioButton
                  id="subscribe-author"
                  name="subscribe_comments"
                  value={COMMENT_SUBSCRIPTION_TYPE.AUTHOR}
                  onClick={this.commentSubscriptionClick}
                  checked={
                    subscriptionType === COMMENT_SUBSCRIPTION_TYPE.AUTHOR
                  }
                />
                <label
                  htmlFor="subscribe-author"
                  className="crayons-field__label"
                >
                  Post author comments
                  <p className="crayons-field__description">
                    You’ll receive notifications only if post author sends a new
                    comment.
                  </p>
                </label>
              </FormField>
            </div>

            <Button
              className="w-100"
              onClick={(_event) => {
                this.setState((prevState) => {
                  onSubscribe(prevState.subscriptionType);

                  return { ...prevState, showOptions: false };
                });
              }}
            >
              Done
            </Button>
          </Dropdown>
        )}
      </div>
    );
  }
}

CommentSubscription.displayName = 'CommentSubscription';

CommentSubscription.propTypes = {
  positionType: PropTypes.oneOf(['absolute', 'relative', 'static']).isRequired,
  onSubscribe: PropTypes.func.isRequired,
  onUnsubscribe: PropTypes.func.isRequired,
  subscriptionType: PropTypes.oneOf(
    Object.entries(COMMENT_SUBSCRIPTION_TYPE).map(([, value]) => value),
  ).isRequired,
  isLoggedIn: PropTypes.bool.isRequired,
};
