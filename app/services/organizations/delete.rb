module Organizations
  class Delete
    def initialize(org)
      @org = org
    end

    def call
      org.destroy
    end

    def self.call(...)
      new(...).call
    end

    private

    attr_reader :org

    # def delete_user_activity
    #   DeleteActivity.call(user)
    # end

    # def delete_comments
    #   DeleteComments.call(user)
    # end

    # def delete_articles
    #   DeleteArticles.call(user)
    # end
  end
end
