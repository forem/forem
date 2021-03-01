class UserSubscriptionTag < LiquidTagBase
  PARTIAL = "liquids/user_subscription".freeze
  VALID_CONTEXTS = %w[Article].freeze
  VALID_ROLES = [
    :admin,
    [:restricted_liquid_tag, LiquidTags::UserSubscriptionTag],
    :super_admin,
  ].freeze

  SCRIPT = <<~JAVASCRIPT.freeze
    const subscribeBtn = document.getElementById('subscribe-btn');

    function isUserSignedIn() {
      return document.head.querySelector('meta[name="user-signed-in"][content="true"]') !== null;
    }

    // Hiding/showing elements
    // If clearSubscribeButton is false, we will not clear out the subscription-signed-in area,
    // which will allow users to re-submit their subscription if they see any error messages.
    // ***************************************
    function clearSubscriptionArea({ clearSubscribeButton = true } = {}) {
      if (!clearSubscribeButton) {
        // Allow users to try submitting again if they see an error.
        hideSubscriptionSignedIn();
      }

      const subscriptionSignedOut = document.getElementById('subscription-signed-out');
      if (subscriptionSignedOut) {
        subscriptionSignedOut.classList.add("hidden");
      }

      hideResponseMessage();

      const subscriberAppleAuth = document.getElementById('subscriber-apple-auth');
      if (subscriberAppleAuth) {
        subscriberAppleAuth.classList.add("hidden");
      }

      hideConfirmationModal();
    }

    // Hides the response message (which displays success/error messages) if it exists.
    // ***************************************
    function hideResponseMessage() {
      const responseMessage = document.getElementById('response-message');
      if (responseMessage) {
        responseMessage.classList.add("hidden");
      }
    }

    function showSignedIn() {
      clearSubscriptionArea();
      const subscriptionSignedIn = document.getElementById('subscription-signed-in');
      if (subscriptionSignedIn) {
        subscriptionSignedIn.classList.remove("hidden");
      }

      const profileImages = document.getElementById('profile-images');
      if (profileImages) {
        profileImages.classList.remove("signed-out");
        profileImages.classList.add("signed-in");
      }
    }

    function showSignedOut() {
      clearSubscriptionArea();

      const subscriptionSignedOut = document.getElementById('subscription-signed-out');
      if (subscriptionSignedOut) {
        subscriptionSignedOut.classList.remove("hidden");
      }

      const profileImages = document.getElementById('profile-images');
      if (profileImages) {
        profileImages.classList.remove("signed-in");
        profileImages.classList.add("signed-out");
      }

      const subscriberProfileImage = document.getElementsByClassName('ltag__user-subscription-tag__subscriber-profile-image')[0];
      if (subscriberProfileImage) {
        subscriberProfileImage.classList.add("hidden");
      }
    }

    function showResponseMessage(noticeType, msg) {
      clearSubscriptionArea(clearSubscribeButton = false);

      const responseMessage = document.getElementById('response-message');
      if (responseMessage) {
        responseMessage.classList.remove("hidden");
        responseMessage.classList.add(`crayons-notice--${noticeType}`);
        responseMessage.textContent = msg;

        if (noticeType === 'danger') {
          // Allow users to try resubscribing if they see an error message.
          subscribeBtn.textContent = "Submit";
          subscribeBtn.disabled = false;
        }
      }
    }

    function showAppleAuthMessage() {
      clearSubscriptionArea();
      const subscriber = userData();
      if (subscriber) {
        updateProfileImages('.ltag__user-subscription-tag__subscriber-profile-image', subscriber);
      }

      const subscriberAppleAuth = document.getElementById('subscriber-apple-auth');
      if (subscriberAppleAuth) {
        subscriberAppleAuth.classList.remove("hidden");
      }
    }

    function showSubscribed() {
      hideSubscriptionSignedIn();
      updateSubscriberData();
      const authorUsername = document.getElementById('user-subscription-tag')?.dataset.authorUsername;
      const alreadySubscribedMsg = `You are already subscribed.`;
      showResponseMessage('success', alreadySubscribedMsg);
    }

    function showConfirmationModal() {
      const confirmationModal = document.getElementById('user-subscription-confirmation-modal');
      if (confirmationModal) {
        confirmationModal.classList.remove("hidden");
      }
    }

    function hideConfirmationModal() {
      const confirmationModal = document.getElementById('user-subscription-confirmation-modal');
      if (confirmationModal) {
        confirmationModal.classList.add("hidden");
      }
    }

    // Updating DOM elements
    // ***************************************
    function updateSubscriberData() {
      const subscriber = userData();
      if (subscriber.email) {
        updateElementsTextContent('.ltag__user-subscription-tag__subscriber-email', subscriber.email);
      }

      updateProfileImages('.ltag__user-subscription-tag__subscriber-profile-image', subscriber);
    }

    function updateElementsTextContent(identifier, value) {
      const elements = document.querySelectorAll(identifier);

      elements.forEach(function(element) {
        element.textContent = value;
      });
    }

    function updateProfileImages(identifier, subscriber) {
      const profileImages = document.querySelectorAll(`img${identifier}`);

      profileImages.forEach(function(profileImage) {
        profileImage.src = subscriber.profile_image_90;
        profileImage.alt = `${subscriber.username} profile image`;
      });
    }

    function hideSubscriptionSignedIn() {
      const subscriptionSignedIn = document.getElementById('subscription-signed-in');
      if (subscriptionSignedIn) {
        subscriptionSignedIn.classList.add("hidden");
      }
    }

    // Adding event listeners for 'click'
    // ***************************************
    function addSignInClickHandler() {
      const signInBtn = document.getElementById('sign-in-btn');
      if (signInBtn) {
        signInBtn.addEventListener('click', function(e) {
          if (typeof showLoginModal !== 'undefined') {
            showLoginModal();
          }
        });
      }
    }

    function addConfirmationModalClickHandlers() {
      if (subscribeBtn) {
        subscribeBtn.addEventListener('click', function(e) {
          showConfirmationModal();
        });
      }

      const cancelBtn = document.getElementById('cancel-btn');
      if (cancelBtn) {
        cancelBtn.addEventListener('click', function(e) {
          hideConfirmationModal();
        });
      }

      const closeConfirmationModal = document.getElementById('close-confirmation-modal');
      if (closeConfirmationModal) {
        closeConfirmationModal.addEventListener('click', function(e) {
          hideConfirmationModal();
        });
      }

      const confirmationModal = document.getElementById('confirmation-btn')
      if (confirmationModal) {
        confirmationModal.addEventListener('click', function(e) {
          handleSubscription();
        });
      }
    }

    // API calls
    // ***************************************
    function submitSubscription() {
      // Hide any error messages previously rendered.
      hideResponseMessage();

      subscribeBtn.textContent = "Submitting...";
      subscribeBtn.disabled = true;

      const headers = {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      }

      const articleBody = document.getElementById('article-body');
      const articleId = (articleBody ? articleBody.dataset.articleId : null);

      const subscriber = userData();
      const body = JSON.stringify(
          {
            user_subscription: {
              source_type: 'Article',
              source_id: articleId,
              subscriber_email: subscriber.email
            }
          }
        )

      return fetch('/user_subscriptions', {
        method: 'POST',
        headers: headers,
        credentials: 'same-origin',
        body: body,
      }).then(function(response) {
        return response.json();
      });
    }

    function fetchIsSubscribed() {
      const articleBody = document.getElementById('article-body');
      const articleId = (articleBody ? articleBody.dataset.articleId : null);

      const params = new URLSearchParams({
        source_type: 'Article',
        source_id: articleId
      }).toString();

      const headers = {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      }

      return fetch(`/user_subscriptions/subscribed?${params}`, {
        method: 'GET',
        headers: headers,
        credentials: 'same-origin',
      }).then(function(response) {
        if (response.ok) {
          return response.json();
        } else {
          console.error(`Base data error: ${response.status} - ${response.statusText}`);
        }
      });
    }

    // Handle API responses
    // ***************************************
    function handleSubscription() {
      hideConfirmationModal(); // Close the modal once the user has confirmed.

      submitSubscription().then(function(response) {
        if (response.success) {
          const userSubscriptionTag = document.getElementById('user-subscription-tag');
          const authorUsername = (userSubscriptionTag ? userSubscriptionTag.dataset.authorUsername : null);
          const successMsg = `You are now subscribed and may receive emails from ${authorUsername}`;
          showResponseMessage('success', successMsg);
          hideSubscriptionSignedIn();
        } else {
          showResponseMessage('danger', response.error);
        }
      });
    }

    function checkIfSubscribed() {
      fetchIsSubscribed().then(function(response) {
        const subscriber = userData();
        const isSubscriberAuthedWithApple = (subscriber.email ? subscriber.email.endsWith('@privaterelay.appleid.com') : false);

        if (response.is_subscribed) {
          showSubscribed();
        } else if (isSubscriberAuthedWithApple) {
          showAppleAuthMessage();
        } else {
          updateSubscriberData();
        }
      });
    }

    // We load this JS on every Article. This is to only run it on Articles
    // where the UserSubscription liquid tag is present
    if (document.getElementById('user-subscription-tag')) {
      // The markup defaults to signed out UX
      if (isUserSignedIn()) {
        showSignedIn();
        addConfirmationModalClickHandlers();

        // We need access to some DOM elements (i.e. csrf token, article id, userData, etc.)
        document.addEventListener('DOMContentLoaded', function() {
          checkIfSubscribed();
        });
      } else {
        showSignedOut();
        addSignInClickHandler();
      }
    }
  JAVASCRIPT

  def initialize(_tag_name, cta_text, parse_context)
    super
    @cta_text = cta_text.strip
    @source = parse_context.partial_options[:source]
    @user = parse_context.partial_options[:user]
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        cta_text: @cta_text,
        author_profile_image: @user&.profile_image_90,
        author_username: @user&.username
      },
    )
  end

  def self.script
    SCRIPT
  end
end

Liquid::Template.register_tag("user_subscription", UserSubscriptionTag)
