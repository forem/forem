module ScheduledAutomations
  ##
  # Executes a scheduled automation by calling the appropriate AI service
  # and performing the requested action (creating a draft or publishing an article).
  #
  # @example Execute an automation
  #   automation = ScheduledAutomation.find(1)
  #   result = ScheduledAutomations::Executor.call(automation)
  #   if result.success?
  #     puts "Created article: #{result.article.title}"
  #   else
  #     puts "Failed: #{result.error_message}"
  #   end
  class Executor
    Result = Struct.new(:success?, :article, :error_message, keyword_init: true)

    class << self
      def call(automation)
        new(automation).call
      end
    end

    def initialize(automation)
      @automation = automation
      @user = automation.user
    end

    def call
      # Check if automation is already running
      if @automation.running?
        return Result.new(
          success?: false,
          article: nil,
          error_message: "Automation is already running"
        )
      end

      # Mark as running to prevent concurrent execution
      @automation.mark_as_running!

      begin
        # Call the appropriate AI service
        service_result = call_ai_service

        # If service returned nil or no content, mark as completed and return
        if service_result.nil?
          next_run_time = @automation.calculate_next_run_time
          @automation.mark_as_completed!(next_run_time)
          
          return Result.new(
            success?: true,
            article: nil,
            error_message: "No content generated (service returned nil)"
          )
        end

        # Create or publish the article based on action
        article = perform_action(service_result)

        # Mark automation as completed and schedule next run
        next_run_time = @automation.calculate_next_run_time
        @automation.mark_as_completed!(next_run_time)

        Result.new(success?: true, article: article, error_message: nil)
      rescue StandardError => e
        # Mark as failed and log error
        @automation.mark_as_failed!
        Rails.logger.error("ScheduledAutomation ##{@automation.id} failed: #{e.class} - #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))

        Result.new(
          success?: false,
          article: nil,
          error_message: "#{e.class}: #{e.message}"
        )
      end
    end

    private

    def call_ai_service
      case @automation.service_name
      when "github_repo_recap"
        call_github_repo_recap_service
      else
        raise ArgumentError, "Unknown service: #{@automation.service_name}"
      end
    end

    def call_github_repo_recap_service
      # Extract service configuration
      repo_name = @automation.action_config["repo_name"]
      days_ago = (@automation.action_config["days_ago"] || 7).to_i

      unless repo_name.present?
        raise ArgumentError, "repo_name is required in action_config for github_repo_recap service"
      end

      # Get GitHub client - use default client (public API)
      # In the future, this could be enhanced to use user credentials if available
      github_client = Github::OauthClient.new

      # Call the service
      service = Ai::GithubRepoRecap.new(
        repo_name,
        days_ago: days_ago,
        github_client: github_client
      )

      # Generate the recap (this will return nil if no activity)
      recap_result = service.generate

      # Augment with additional instructions if provided
      if recap_result && @automation.additional_instructions.present?
        recap_result.body = augment_with_instructions(recap_result.body)
      end

      recap_result
    end

    def augment_with_instructions(body)
      instructions = @automation.additional_instructions.strip
      
      # Add instructions as a footer section
      <<~AUGMENTED
        #{body}

        ---

        **Additional Context:**
        #{instructions}
      AUGMENTED
    end

    def perform_action(service_result)
      case @automation.action
      when "create_draft"
        create_article(service_result, published: false)
      when "publish_article"
        create_article(service_result, published: true)
      else
        raise ArgumentError, "Unknown action: #{@automation.action}"
      end
    end

    def create_article(service_result, published:)
      article = Article.new(
        user: @user,
        title: service_result.title,
        body_markdown: service_result.body,
        published: published
      )

      # Set published_at if publishing
      article.published_at = Time.current if published

      # Apply any additional article configuration
      apply_article_config(article)

      # Save the article
      article.save!

      article
    end

    def apply_article_config(article)
      config = @automation.action_config

      # Set tags if specified
      if config["tags"].present?
        article.tag_list = config["tags"]
      end

      # Set organization if specified
      if config["organization_id"].present?
        article.organization_id = config["organization_id"].to_i
      end

      # Set subforem if specified
      if config["subforem_id"].present?
        article.subforem_id = config["subforem_id"].to_i
      end
    end
  end
end

