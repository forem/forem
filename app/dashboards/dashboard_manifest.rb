# DashboardManifest tells Administrate which dashboards to display
class DashboardManifest
  # `DASHBOARDS`
  # a list of dashboards to display in the side navigation menu
  #
  # These are all of the rails models that we found in your database
  # at the time you installed Administrate.
  #
  # To show or hide dashboards, add or remove the model name from this list.
  # Dashboards returned from this method must be Rails models for Administrate
  # to work correctly.
  DASHBOARDS = %i[
    articles
    users
    organizations
    comments
    follows
    reactions
    podcasts
    podcast_episodes
    collections
    tags
    email_messages
    feedback_messages
    display_ads
    badges
    badge_achievements
    html_variants
    html_variant_trials
    html_variant_successes
    sponsorships
    pro_memberships
  ].freeze
  # DASHBOARDS = [
  #   :users,
  #   :articles,
  #   :podcast_episodes,
  # ]
  # `ROOT_DASHBOARD`
  # the name of the dashboard that will be displayed
  # at "http://your_site.com/admin"
  #
  # This dashboard will likely be the first page that admins see
  # when they log into the dashboard.
  ROOT_DASHBOARD = DASHBOARDS.first
end
