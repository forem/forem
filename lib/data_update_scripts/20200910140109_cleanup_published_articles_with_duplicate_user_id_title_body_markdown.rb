module DataUpdateScripts
  class CleanupPublishedArticlesWithDuplicateUserIdTitleBodyMarkdown
    def run
      # load all published duplicates
      rows = ActiveRecord::Base.connection.execute(
        <<~SQL.squish,
          SELECT *
          FROM
              (SELECT *,
                      ROW_NUMBER() OVER(PARTITION BY user_id, title, body_markdown) AS row_number,
                      COUNT(*) OVER(PARTITION BY user_id, title, body_markdown) AS num_rows_in_partition
               FROM articles) duplicates
          WHERE published = 't'
              AND num_rows_in_partition > 1 -- we select all rows in each partition with duplicates
        SQL
      )

      articles_to_delete_ids = []
      ActiveRecord::Base.transaction do
        # now that we have all rows in the partition, we group them by the partition columns
        # so we can have small groups referring to the same article and graft data of surplus articles
        # onto the first of the partition (it doesn't really matter which one we're going to use as the "mold")
        groups = rows.group_by { |row| [row["user_id"], row["title"], row["body_markdown"]] }

        # for each group we select the first, and then graft the data of the other ones on to it

        groups.each_value do |group|
          article_to_keep = group.first
          articles_to_graft = group[1..]

          article = Article.find(article_to_keep["id"])

          graft_articles(article, articles_to_graft)

          # save all the magic
          article.save
          article.index_to_elasticsearch_inline

          articles_to_delete_ids += articles_to_graft.map { |a| a["id"] }
        end

        # we shouldn't need to call Articles::Destroy as all the data has been moved over by now
        Article.where(id: articles_to_delete_ids).destroy_all
      end

      return if articles_to_delete_ids.blank?

      # Store deleted IDs temporarily in Redis for safe keeping
      Rails.cache.write(
        "DataUpdateScripts::CleanupPublishedArticlesWithDuplicateUserIdTitleBodyMarkdown",
        articles_to_delete_ids,
        expires_in: 2.weeks,
      )
    end

    private

    # Main goal here is copy and merge everything from the duplicates to the main one
    # NOTE: I'm intentionally ignore the case that two duplicates belong to different orgs
    # or different collections as it's highly unlikely
    def graft_articles(article_to_keep, articles_to_graft)
      article_id = article_to_keep.id
      articles_to_graft_ids = articles_to_graft.map { |a| a["id"] }

      # NotificationSubscription, Notification and RatingVote rows will be removed
      # Poll is ignored because it's related to the liquid tag inside the article, also user's can't use polls
      # TagAdjustment is ignored as there's likely no reason for article to have an adjustment moved over
      models_with_a_direct_relation = [
        HtmlVariantSuccess,
        HtmlVariantSuccess,
        HtmlVariantTrial,
        PageView,
      ]
      models_with_a_direct_relation.each do |model_class|
        model_class.where(article_id: articles_to_graft_ids).update_all(article_id: article_id)
      end

      Comment
        .where(commentable_type: "Article", commentable_id: articles_to_graft_ids)
        .update_all(commentable_id: article_id)

      ProfilePin
        .where(pinnable_type: "Article", pinnable_id: articles_to_graft_ids)
        .update_all(pinnable_id: article_id)

      # we add tags that are not already present in the article from the others
      # we don't really need to graft these as the tag objects belonging to the soon to be
      # destroyed copies will be removed when we destroy the articles
      tag_ids = ActsAsTaggableOn::Tagging
        .where(taggable_type: "Article", taggable_id: articles_to_graft_ids)
        .pluck(:tag_id)

      tags = Tag.where(id: tag_ids).pluck(:id, :name)

      # if the union of the two sets equals the article tags, then there's nothing to copy over
      tag_names_to_maybe_graft = tags.map(&:second)
      return if article_to_keep.tag_list == article_to_keep.tag_list | tag_names_to_maybe_graft

      article_to_keep.tag_list.add(*(article_to_keep.tag_list - tag_names_to_maybe_graft))
    end
  end
end
