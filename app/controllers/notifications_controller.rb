class NotificationsController < ApplicationController
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # No authorization required because we provide authentication on notifications page
  def index
    unless user_signed_in?
      redirect_to new_magic_link_path and return
    end

    @user = user_to_view

    @initial_page_size = 8

    # NOTE: this controller is using offset based pagination by assuming that
    # the id of the last notification also corresponds to the newest `notified_at`
    # this might not be forever true but it's good enough for now
    if params[:offset]
      num = 30
      notified_at_offset = Notification.select(:notified_at).find(params[:offset])&.notified_at
    else
      num = @initial_page_size
    end

    @notifications = if (params[:org_id].present? || params[:filter] == "org") && allowed_user?
                       organization_notifications
                     elsif params[:org_id].blank? && params[:filter].present?
                       filtered_notifications
                     else
                       @user.notifications
                     end
    # Wrap `notified_at` in an expression so high-volume accounts in `pg_stats.most_common_vals`
    # use the `user_id`/`organization_id` B-tree indexes + `Sort` rather than an unbounded
    # backward walk across the 4.76 GB global `index_notifications_on_notified_at` index.
    @notifications = @notifications.from_subforem.order(
      Arel.sql("(notifications.notified_at + INTERVAL '0 seconds') DESC"),
    )

    # if offset based pagination is invoked by the frontend code, we filter out all earlier ones
    if notified_at_offset
      @notifications = @notifications.where(
        "(notifications.notified_at + INTERVAL '0 seconds') < ?", notified_at_offset
      )
    end

    @notifications = @notifications.limit(num)

    @notifications = NotificationDecorator.decorate_collection(@notifications)

    # Only the ids are needed (as cache-key parts), so avoid hydrating full rows
    # (comments carry body_markdown, processed_html and semantic_embedding).
    # Order by `(id + 0) DESC` so high-volume accounts in `pg_stats.most_common_vals` use the
    # `user_id` B-tree indexes + `Sort` (trading a bounded scan/sort of the user's own rows
    # against an unbounded multi-second backward walk across the full `reactions_pkey` /
    # `comments_pkey` table on `LIMIT 1` when they haven't reacted or commented recently).
    @last_user_reaction = @user.reactions.order(Arel.sql("reactions.id + 0 DESC")).pick(:id)
    @last_user_comment = @user.comments.order(Arel.sql("comments.id + 0 DESC")).pick(:id)

    @organizations = @user.member_organizations if @user.organizations
    @selected_organization = Organization.find(params[:org_id]) if params[:org_id].present?

    # The first call, the one coming from the browser URL bar will render the "index" view, which renders
    # the first few notifications. After that the JS frontend code (see `initNotification.js`)
    # will call this action again by sending the offset id for the last known notifications, the result
    # will be the partial rendering of only the list of notifications that will be attached to the DOM by JS
    if notified_at_offset
      render partial: "notifications_list"
    else
      # [@jeremyf] I added an explicit render.  Before adding the explicit render, we relied on the
      # implicit render cycle of Rails.  Which is fine, but it's very disarming to read `render
      # partial: "notifications_list" if notified_at_offset` as the last line of the method.
      #
      # My hope is that this explicit render removes at least one future head scratch.
      render "index"
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  private

  def user_to_view
    if params[:username] && current_user.super_admin?
      User.find_by(username: params[:username])
    else
      current_user
    end
  end

  def filtered_notifications
    if params[:filter].to_s.casecmp("posts").zero?
      @user.notifications.for_published_articles
    elsif params[:filter].to_s.casecmp("comments").zero?
      @user.notifications.for_comments_and_mentions
    else
      @user.notifications
    end
  end

  def organization_notifications
    org_id = params[:org_id]

    if params[:filter].to_s.casecmp("comments").zero?
      Notification.for_organization_comments_and_mentions(org_id)
    else
      Notification.for_organization(org_id)
    end
  end

  def allowed_user?
    @user.org_member?(params[:org_id]) || @user.super_admin?
  end
end
