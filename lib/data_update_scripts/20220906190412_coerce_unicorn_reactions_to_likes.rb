module DataUpdateScripts
  class CoerceUnicornReactionsToLikes
    def run
      # Find all unicorn reactions where there exists a like reaction on the same reactable
      # by the same user, and delete them (These would cause errors when we try to flip all
      # the unicorn reactions to a like)
      ActiveRecord::Base.connection.execute(
        <<-SQL,
          DELETE FROM reactions
          WHERE id IN(
              SELECT
                unicorn_reactions.id FROM reactions AS unicorn_reactions
                JOIN reactions AS like_reactions ON unicorn_reactions.user_id = like_reactions.user_id
                  AND unicorn_reactions.reactable_id = like_reactions.reactable_id
                  AND unicorn_reactions.reactable_type = like_reactions.reactable_type
              WHERE
                unicorn_reactions.category = 'unicorn'
                AND like_reactions.category = 'like')
        SQL
      )

      # Find all reactions with unicorn reactions, flip them to like, (callbacks will update their scores)
      Reaction.where(category: "unicorn").find_each(order: :desc) do |reaction|
        reaction.update(category: "like")
        reaction.save
      end
    end
  end
end
