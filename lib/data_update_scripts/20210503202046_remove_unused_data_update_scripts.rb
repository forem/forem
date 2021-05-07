module DataUpdateScripts
  class RemoveUnusedDataUpdateScripts
    FILE_NAMES = %w[
      20200214171607_index_tags_to_elasticsearch
      20200217131245_re_index_existing_articles_with_approved
      20200217215802_index_listings_to_elasticsearch
      20200218195023_index_chat_channel_memberships_to_elasticsearch
      20200225114328_update_tags_social_preview_templates
      20200305201627_index_users_to_elasticsearch
      20200326145114_re_index_feed_content_to_elasticsearch
      20200406213152_re_index_users_to_elasticsearch
      20200410152018_resync_elasticsearch_documents
      20200415200651_index_reading_list_reactions
      20200518173504_update_public_reactions_count_from_positive_reactions_count
      20200519142908_re_index_feed_content_and_users_to_elasticsearch
      20200729120730_remove_orphaned_ahoy_events
      20200803142830_reindex_listing_search_column
      20200805171911_clean_up_language_settings
      20200819025131_migrate_profile_data
      20200901194251_reindex_reading_list_reactions
      20200904132553_remove_draft_articles_with_duplicate_feed_source_url
      20200911045602_reindex_articles_with_videos
      20200914042434_reindex_users_for_profiles
      20200924140813_remove_reaction_index_by_name
      20201013205258_resave_articles_and_comments_for_imgproxy
      20201014184856_resave_users_for_imgproxy
      20201019163242_resave_articles_and_comments_for_imgproxy
      20201020215535_resave_articles_and_comments_for_imgproxy
      20201030134117_reindex_users_for_username_search
      20201103050112_prepare_for_profile_column_drop
      20201210163704_set_contact_email_address
      20201217184442_append_community_to_community_name
      20201218173445_remove_collective_noun_from_config
      20210104170542_resave_articles_for_code_snippet_fullscreen_icon
      20210118194138_resync_unpublished_articles_comments_elasticsearch_document
      20210203104631_add_single_resource_admin_role_to_users_with_tech_admin
      20210218041143_backfill_usernames
    ].freeze

    def run
      # DataUpdateScript does not have any callbacks so delete_all is okay over destroy_all
      # delete is also idempotent by default, returning 0 if no records are deleted
      DataUpdateScript.delete_by(file_name: FILE_NAMES)
    end
  end
end
