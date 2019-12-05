module Stories
  class Show
    attr_reader :first_scope, :second_scope, :moderate, :preview_value, :user_signed_in, :variant_version

    def initialize(first_scope:, second_scope:, moderate:, preview_value:, user_signed_in:, variant_version:)
      @first_scope = first_scope
      @second_scope = second_scope
      @moderate = moderate
      @preview_value = preview_value
      @user_signed_in = user_signed_in
      @variant_version = variant_version
    end

    def execute
      case url_format
      when "author/article"
        presenter = Articles::Show.execute(article_by_path, variant_version: variant_version,
                                                            preview_value: preview_value,
                                                            user_signed_in: user_signed_in)
        OpenStruct.new(presenter: presenter, surrogate_key: presenter.record_key, template: "articles/show")
      when "author/article?moderate"
        OpenStruct.new(redirect: true, destination_url: "/internal/articles/#{article_presenter.id}")
      when "podcast/episode"
        OpenStruct.new(presenter: PodcastShowPresenter.new(podcast, episode),
                       surrogate_key: episode.record_key,
                       template: "podcast_episodes/show")
      when "old_authorname/article"
        OpenStruct.new(redirect: true, destination_url: URI.parse("/#{potential_author.username}/#{article_by_slug.slug}").path)
      when "organization/article"
        OpenStruct.new(redirect: true, destination_url: URI.parse("/#{article_by_slug.organization.slug}/#{article_by_slug.slug}").path)
      else
        raise ActiveRecord::RecordNotFound, "Not Found" # this is not covered by tests
      end
    end

    private

    def url_format
      article_was_created_by_potential_author = potential_author&.articles&.find_by(slug: article_by_slug&.slug)
      article_belongs_to_organization = article_by_slug&.organization
      article_was_found_by_path = !article_by_path.nil?
      article_was_found_by_slug = !article_by_slug.nil?
      moderate_option = moderate

      if article_was_found_by_path
        "author/article"
      elsif article_was_found_by_path && moderate_option
        "author/article?moderate"
      elsif article_was_found_by_slug && article_was_created_by_potential_author
        "old_authorname/article"
      elsif article_was_found_by_slug && article_belongs_to_organization
        "organization/article"
      elsif article_was_found_by_slug
        "other"
      else
        "podcast/episode"
      end
    end

    def article_by_path
      @article_by_path ||= Article.find_by(path: "/#{first_scope.downcase}/#{second_scope}")&.decorate
    end

    def article_by_slug
      @article_by_slug ||= Article.find_by(slug: second_scope)&.decorate
    end

    def potential_author
      # Search potential author considering old usernames
      potential_authorname = first_scope.tr("@", "").downcase
      @potential_author ||= User.find_by("old_username = ? OR old_old_username = ?", potential_authorname, potential_authorname)
    end

    def podcast
      @podcast ||= Podcast.available.find_by(slug: first_scope)
    end

    def episode
      @episode ||= PodcastEpisode.available.find_by(slug: second_scope)&.decorate
    end
  end
end
