module DataUpdateScripts
  class RemoveSiteConfigScripts
    SCRIPTS_TO_REMOVE = %w[
      20201001173841_add_navigation_links
      20201218080343_update_default_email_addresses
      20210305222641_resave_users_for_imgproxy_update
      20210322092753_fill_badges_credits_awarded
      20210430043750_remove_site_config_secondary_logo
      20210512033821_clean_up_site_config
      20210517091342_remove_shop_url_from_site_config
    ].freeze

    def run
      DataUpdateScript.delete_by(file_name: SCRIPTS_TO_REMOVE)
    end
  end
end
