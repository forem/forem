module Authorizer
  # @api private
  #
  # This module is the container for authorization enforcement
  # considerations.
  #
  # It does not define how we administer the authorization datastore.
  # That is a separate (as yet to be described) module; perhaps we
  # could call it Authorizer::Administration.
  #
  # From the application's non-adminsitrative perspective, we want to
  # avoid asking questions such as `render_edit_button_for(@article)
  # if user.admin?`.  The non-administrative portion should instead as
  # `render_edit_button_for(@article) if user.authorized_to?(resource:
  # @article, action: :edit)`.
  #
  # This aligns with Pundit's mindset and decouples knowledge of user
  # roles from the UI and controller layers.  Which in turn allows for
  # each Forem to articulate the policy around rendering the edit
  # button for an article.
  module Enforcement
    # @api private
    # @abstract
    #
    # The purpose of this module is to begin to describe the methods
    # necessary for enforcing permissions.
    #
    # - Do we render a button?
    # - Do we authorize you to take an action?
    # - What do we filter out of a query?
    # - Who all can edit this article?
    # - What all can I edit?
    #
    # Some of the above questions may not be immediately necessary.
    #
    # @note For the examples below, assume that we have the following
    #       ruby code:
    #
    #       ```ruby
    #       class AuthorizationLayer
    #         include Authorizer::Enforcement::QueryInterface
    #       end
    #       auth_layer = AuthorizationLayer.new
    #       ```
    #
    # @note the "What do we filter out of a query" is a harder
    #       question to answer.
    module QueryInterface
      # @abstract
      #
      # Answers the question: "Can the given :user take the given :action on the
      # given :resource :within the given concept?"
      #
      # @param user [User] who is taking the action.
      # @param action [Symbol,String] what is being done to the subject.
      # @param resource [Object] what is the user acting on
      # @param within [Object] what is the containing concept within which the
      #        given user is taking the action.  This is necessary when we think
      #        about creating something (see examples below); this implies that
      #        all things must be created within something else (e.g. Create a
      #        ContentGroup within a Site).
      #
      # @return [Boolean]
      #
      # @example
      #   # Can the user create an article
      #   user = User.first
      #   auth_layer.authorized?(user: user, action: :create, resource: Article, within: ContentGroup.first)
      #
      # @example
      #   # Can the user edit the article
      #   user = User.first
      #   auth_layer.authorized?( user: user, action: :edit, resource: user.articles.first )
      def authorized?(user:, action:, resource:, within: nil)
        raise NotImplementedError
      end
    end

    # This module addresses [Roles and Authorization system master doc][1] and
    # assumes that we've wired in it's use in places where we allow the creation
    # and editing of posts.  It assumes that the only resources we'll be asking
    # about are Article.
    #
    # > All users with any administrative roles can post, and all users without it can't.
    #
    # [1]:https://docs.google.com/document/d/1mPd40UazOsa6gLoD4AXVpXaXN9GGIACLfhu8HCnF-rE/edit#heading=h.d0tbn14xnndf
    module UseCaseOneDashOne
      # rubocop:disable Lint/UnusedMethodArgument
      def authorized?(user:, action:, resource:, within: nil)
        return true if (resource.is_a?(Article) || resource == Article) && user.admin?

        raise "I'm sorry, we can't handle authorizing #{resource} at this time."
      end
      # rubocop:enable Lint/UnusedMethodArgument
    end
  end
end
