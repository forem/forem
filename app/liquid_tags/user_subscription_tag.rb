class UserSubscriptionTag < LiquidTagBase
  PARTIAL = "liquids/user_subscription".freeze

  SCRIPT = <<~JAVASCRIPT.freeze
    function isUserSignedIn() {
      return document.head.querySelector('meta[name="user-signed-in"][content="true"]') !== null;
    }

    function showSignedIn() {
      subscriptionSignedOut.style.display = 'none';
      subscriptionSignedIn.style.display = 'block';
    }

    function addSignInClickEvent() {
      if (signInBtn !== null) {
        signInBtn.addEventListener('click', function(e) {
          if (typeof showModal !== "undefined") {
            showModal('email_signup');
          }
        });
      }
    }

    async function fetchBaseData() {
      let params = new URLSearchParams({
        author_id: authorId,
        source_type: "Article",
        source_id: articleId
      }).toString();

      let headers = {
        Accept: 'application/json',
        'X-CSRF-Token': window.csrfToken,
        'Content-Type': 'application/json',
      }

      let response = await fetch(`/user_subscriptions/base_data?${params}`, {
        method: 'GET',
        headers: headers,
        credentials: 'same-origin',
      });

      let data = await response.json()

      return data;
    }

    const articleId = document.getElementById('article-body').dataset.articleId;
    const authorId = document.getElementById('article-show-container').dataset.authorId;
    const signInBtn = document.getElementById('sign-in-btn');
    const subscriptionSignedIn = document.getElementById('subscription-signed-in');
    const subscriptionSignedOut = document.getElementById('subscription-signed-out');

    const userSubscriptionBaseData = fetchBaseData();

    // The markup defaults to signed out UX
    if (isUserSignedIn()) {
      showSignedIn();
    } else {
      addSignInClickEvent();
    }
  JAVASCRIPT

  def initialize(_tag_name, cta_text, _tokens)
    @cta_text = cta_text.strip
  end

  def render(_context)
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        cta_text: @cta_text
      },
    )
  end

  def self.script
    SCRIPT
  end
end

Liquid::Template.register_tag("user_subscription", UserSubscriptionTag)
