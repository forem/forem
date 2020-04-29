import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import {
  Button,
  ButtonGroup,
  Dropdown,
  FormField,
  RadioButton,
} from '@crayons';
import { CogIcon } from '../icons';

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
    const { base: element } = this.dropdownElement;

    if (showOptions) {
      window.addEventListener('scroll', this.dropdownPlacementHandler);
      this.dropdownPlacementHandler();

      this.leftOptionsPanel = (event) => {
        event.stopPropagation();
        this.mousedOut = true;
      };

      element.addEventListener('mouseout', this.leftOptionsPanel, true);

      this.enteredOptionsPanel = (_event) => {
        this.mousedOut = false;
      };

      element.addEventListener('mouseover', this.enteredOptionsPanel);

      this.closeOnOutsideClick = (_event) => {
        if (!this.mousedOut) {
          return;
        }

        this.setState({ showOptions: false });
      };

      window.addEventListener('click', this.closeOnOutsideClick);
    } else {
      element.removeEventListener('mouseout', this.leftOptionsPanel);
      element.removeEventListener('mouseover', this.enteredOptionsPanel);
      window.removeEventListener('scroll', this.dropdownPlacementHandler);
      window.removeEventListener('click', this.closeOnOutsideClick);
    }
  }

  componentWillUnmount() {
    const { base: element } = this.dropdownElement;

    element.removeEventListener('mouseout', this.leftOptionsPanel);
    element.removeEventListener('mouseover', this.enteredOptionsPanel);
    window.removeEventListener('scroll', this.dropdownPlacementHandler);
    window.removeEventListener('click', this.closeOnOutsideClick);
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
    } = this.props;

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
              if (subscribed) {
                onUnsubscribe(COMMENT_SUBSCRIPTION_TYPE.NOT_SUBSCRIBED);
                this.setState({
                  subscriptionType: COMMENT_SUBSCRIPTION_TYPE.ALL,
                });
              } else {
                onSubscribe(subscriptionType);
              }

              this.setState({ subscribed: !subscribed });
            }}
          >
            {subscribed ? 'Unsubscribe' : 'Subscribe'}
          </Button>
          {subscribed && (
            <Button
              variant="outlined"
              icon={CogIcon}
              contentType="icon"
              onClick={(_event) => {
                this.mousedOut = false;
                this.setState({ showOptions: !showOptions });
              }}
            />
          )}
        </ButtonGroup>
        {subscribed && (
          <Dropdown
            className={
              showOptions
                ? `inline-block z-10 right-4 left-4 s:right-0 s:left-auto${
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
};
