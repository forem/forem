class UserSubscriptionTag < LiquidTagBase
  PARTIAL = "liquids/user_subscription".freeze
  VALID_CONTEXTS = %w[Article].freeze
  VALID_ROLES = %i[
    admin
    super_admin
  ].freeze

  SCRIPT = <<~JAVASCRIPT.freeze
    function isUserSignedIn() {
      return document.head.querySelector('meta[name="user-signed-in"][content="true"]') !== null;
    }

    // Hiding/showing elements
    // ***************************************
    function clearSubscriptionArea() {
      document.getElementById('subscription-signed-in').style.display = 'none';
      document.getElementById('subscription-signed-out').style.display = 'none';
      document.getElementById('response-message').style.display = 'none';
      document.getElementById('subscriber-apple-auth').style.display = 'none';
      hideConfirmationModal();
    }

    function showSignedIn() {
      clearSubscriptionArea();
      document.getElementById('subscription-signed-in').style.display = 'block';
    }

    function showResponseMessage(noticeType, msg) {
      clearSubscriptionArea();

      const responseMessage = document.getElementById('response-message')
      responseMessage.style.display = 'block';
      responseMessage.classList.add(`crayons-notice--${noticeType}`);
      responseMessage.textContent = msg;
    }

    function showAppleAuthMessage() {
      clearSubscriptionArea();
      document.getElementById('subscriber-apple-auth').style.display = 'block';
    }

    function showSubscribed() {
      updateSubscriberData();
      const authorUsername = document.getElementById('user-subscription-tag').dataset.authorUsername;
      const alreadySubscribedMsg = `You are already subscribed!`;
      showResponseMessage('success', alreadySubscribedMsg);
    }

    function showConfirmationModal() {
      document.getElementById('user-subscription-confirmation-modal').style.display = 'block';
    }

    function hideConfirmationModal() {
      document.getElementById('user-subscription-confirmation-modal').style.display = 'none';
    }

    // Updating DOM elements
    // ***************************************
    function updateSubscriberData() {
      const subscriber = userData();

      if (subscriber) {
        updateElementsTextContent('.ltag__user-subscription-tag__subscriber-email', subscriber.email);
        updateProfileImages('.ltag__user-subscription-tag__subscriber-profile-image', subscriber);
      }
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
        profileImage.style.display = 'block';
      });

      const profileImageWrappers = document.querySelectorAll(`span${identifier}`);

      profileImageWrappers.forEach(function(profileImageWrapper) {
        profileImageWrapper.style.display = 'inline-block';
      });
    }

    // Adding event listeners for 'click'
    // ***************************************
    function addSignInClickHandler() {
      document.getElementById('sign-in-btn').addEventListener('click', function(e) {
        if (typeof showModal !== 'undefined') {
          showModal('email_signup');
        }
      });
    }

    function addConfirmationModalClickHandlers() {
      document.getElementById('subscribe-btn').addEventListener('click', function(e) {
        showConfirmationModal();
      });

      document.getElementById('cancel-btn').addEventListener('click', function(e) {
        hideConfirmationModal();
      });

      document.getElementById('close-confirmation-modal').addEventListener('click', function(e) {
        hideConfirmationModal();
      });

      document.getElementById('confirmation-btn').addEventListener('click', function(e) {
        handleSubscription();
      });
    }

    // API calls
    // ***************************************
    function submitSubscription() {
      const headers = {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      }

      const articleId = document.getElementById('article-body').dataset.articleId;
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
      const articleId = document.getElementById('article-body').dataset.articleId;

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
      submitSubscription().then(function(response) {
        if (response.success) {
          const authorUsername = document.getElementById('user-subscription-tag').dataset.authorUsername;
          const successMsg = `You are now subscribed and may receive emails from ${authorUsername}`;
          showResponseMessage('success', successMsg);
        } else {
          showResponseMessage('danger', response.error);
        }
      });
    }

    function checkIfSubscribed() {
      fetchIsSubscribed().then(function(response) {
        const subscriber = userData();
        const isSubscriberAuthedWithApple = subscriber.email.endsWith('@privaterelay.appleid.com');

        if (response.is_subscribed) {
          showSubscribed();
        } else if (isSubscriberAuthedWithApple) {
          showAppleAuthMessage();
        } else {
          updateSubscriberData();
        }
      });
    }

    // The markup defaults to signed out UX
    if (isUserSignedIn()) {
      showSignedIn();
      addConfirmationModalClickHandlers();

      // We need access to some DOM elements (i.e. csrf token, article id, userData, etc.)
      document.addEventListener('DOMContentLoaded', function() {
        checkIfSubscribed();
      });
    } else {
      addSignInClickHandler();
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
