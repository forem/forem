class UserSubscriptionTag < LiquidTagBase
  PARTIAL = "liquids/user_subscription".freeze

  SCRIPT = <<~JAVASCRIPT.freeze
    function isUserSignedIn() {
      return document.head.querySelector('meta[name="user-signed-in"][content="true"]') !== null;
    }

    function showSignedIn() {
      document.getElementById('subscription-signed-in').style.display = 'block';
      document.getElementById('subscription-signed-out').style.display = 'none';
    }

    function addSignInClickHandler() {
      document.getElementById('sign-in-btn').addEventListener('click', function(e) {
        if (typeof showModal !== "undefined") {
          showModal('email_signup');
        }
      });
    }

    function showConfirmationModal() {
      document.getElementById('user-subscription-confirmation-modal').style.display = 'block';
    }

    function hideConfirmationModal() {
      document.getElementById('user-subscription-confirmation-modal').style.display = 'none';
    }

    function submitSubscription() {
      // TODO hit API to create subscription
      console.log("SUBSCRIBED");
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
        submitSubscription();
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

    function checkIfSubscribed() {
      fetchIsSubscribed().then(function(response) {

        if (response.is_subscribed) {
          showSubscribed();
        } else {
          updateSubscriberData();
        }
      });
    }

    function showSubscribed() {
      console.log("ALREADY SUBSCRIBED");
    }

    function updateSubscriberData() {
      const subscriber = userData();

      if (subscriber) {
        updateElementsInnerHTML('.subscriber-email', subscriber.email);
        updateProfileImages('.subscriber-profile-image', subscriber);
      }
    }

    function updateElementsInnerHTML(identifier, value) {
      const elements = document.querySelectorAll(identifier);

      elements.forEach(function(element) {
        element.innerHTML = value;
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

    // The markup defaults to signed out UX
    if (isUserSignedIn()) {
      showSignedIn();
      addConfirmationModalClickHandlers();

      // We need access to some DOM elements (i.e. csrf token, article id, userData, etc.)
      document.addEventListener("DOMContentLoaded", function() {
        checkIfSubscribed();
      });
    } else {
      addSignInClickHandler();
    }
  JAVASCRIPT

  def initialize(_tag_name, cta_text, _tokens)
    @cta_text = cta_text.strip
  end

  def render(context)
    source = detect_in_context(:source, context)
    author = source&.user
    author_profile_image = author&.profile_image_90
    author_username = author&.username

    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        cta_text: @cta_text,
        author_profile_image: author_profile_image,
        author_username: author_username
      },
    )
  end

  def self.script
    SCRIPT
  end
end

Liquid::Template.register_tag("user_subscription", UserSubscriptionTag)
