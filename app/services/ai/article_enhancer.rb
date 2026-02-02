module Ai
  ##
  # Enhances articles by calculating clickbait scores and generating tags.
  # This service provides AI-powered analysis to improve article metadata
  # and content quality assessment.
  class ArticleEnhancer
    # @param article [Article] The article to be enhanced.
    # @param ai_client [Ai::Base] Optional AI client for dependency injection (useful for testing).
    def initialize(article, ai_client: nil)
      @ai_client = ai_client || Ai::Base.new
      @article = article
    end

    ##
    # Calculates the clickbait score for the article title.
    # Retries once on failure.
    #
    # @return [Float] The clickbait score between 0.0 and 1.0.
    def calculate_clickbait_score
      attempt = 0
      max_retries = 1

      begin
        attempt += 1
        system = "You are a content quality bot who ranks titles from 0.0 to 1.0 based on how click-baity they are where 0.0 is not at all clickbaity and 1.0 is unimstakably egregious clickbait. Output ONLY the number with no additional text. i.e. 0.1, 0.34, etc."
        prompt = "On a scale of 0.0 to 1.0 where 0.0 is not at all clickbaity and 1.0 is unimstakably egregious clickbait, return a value indicating the likelihood that the following title is click-bait:\n\n#{@article.title}\n\nTypes of clickbait include listicles such as '11 free and fun APIs you must use in your side project', or overly sensationalist titles such as 'The most amazing thing you will ever see in your life' or all-caps sensationalism like RAILS IS DEAD. Rank from 0.0 to 1.0 based on egregiousness of clickbait."

        response = deliver_chat_result(prompt, system, 0.1)
        parse_clickbait_score(response)
      rescue StandardError => e
        Rails.logger.error("Clickbait score calculation failed (attempt #{attempt}/#{max_retries + 1}): #{e}")

        if attempt <= max_retries
          Rails.logger.info("Retrying clickbait score calculation (attempt #{attempt + 1}/#{max_retries + 1})")
          retry
        else
          Rails.logger.error("Clickbait score calculation failed after #{max_retries + 1} attempts, falling back to default")
          0.0 # Safe default
        end
      end
    end

    ##
    # Generates likely tags for the article if it doesn't have tags.
    # Uses a two-pass approach: first selects top 10 by name relevance,
    # then narrows to 2-4 using tag summaries. Retries once on failure.
    #
    # @return [Array<String>] Array of suggested tag names.
    def generate_tags
      return [] if @article.cached_tag_list.present?

      attempt = 0
      max_retries = 1

      begin
        attempt += 1

        # Get relevant tags for this subforem, limited to top 150 by hotness
        candidate_tags = get_candidate_tags
        return [] if candidate_tags.empty?

        # First pass: Select top 10 most relevant tags by name only
        top_ten_tags = select_top_ten_tags(candidate_tags)
        return [] if top_ten_tags.empty?

        # Second pass: Use tag summaries to select final 2-4 tags
        select_final_tags(top_ten_tags)
      rescue StandardError => e
        Rails.logger.error("Tag generation failed (attempt #{attempt}/#{max_retries + 1}): #{e}")

        if attempt <= max_retries
          Rails.logger.info("Retrying tag generation (attempt #{attempt + 1}/#{max_retries + 1})")
          retry
        else
          Rails.logger.error("Tag generation failed after #{max_retries + 1} attempts, falling back to default")
          [] # Safe default
        end
      end
    end

    private

    ##
    # Delivers a chat result using the AI client with system and user prompts.
    # @param prompt [String] The user prompt.
    # @param system [String] The system prompt.
    # @param temperature [Float] The temperature for the AI response.
    # @return [String] The AI response.
    def deliver_chat_result(prompt, system, temperature)
      full_prompt = "#{system}\n\n#{prompt}"
      @ai_client.call(full_prompt)
    end

    ##
    # Parses the clickbait score response from the AI.
    # @param response [String] The AI response.
    # @return [Float] The parsed clickbait score.
    def parse_clickbait_score(response)
      return 0.0 unless response

      # Extract the first number from the response (including negative numbers)
      score = response.strip.match(/-?\d+\.?\d*/)&.to_s&.to_f
      return 0.0 unless score

      # Ensure score is between 0.0 and 1.0
      [[score, 0.0].max, 1.0].min
    end

    ##
    # Gets candidate tags for the article's subforem, limited to top 150 by hotness.
    # @return [ActiveRecord::Relation<Tag>] Candidate tags.
    def get_candidate_tags
      Tag.from_subforem(@article.subforem_id)
        .supported
        .order(hotness_score: :desc)
        .limit(150)
    end

    ##
    # First pass: Select top 10 most relevant tags by name only.
    # @param candidate_tags [ActiveRecord::Relation<Tag>] Available tags.
    # @return [Array<Tag>] Top 10 most relevant tags.
    def select_top_ten_tags(candidate_tags)
      tag_names = candidate_tags.pluck(:name).join(",")

      system = "Act as a tag relevance analyzer. Output only the tag names as a comma-separated list (e.g. 'javascript,webdev,react') with no additional text. Select the 10 most relevant tags from the provided list."
      prompt = "Given the following article content, select the 10 most relevant tags from this list: #{tag_names}\n\nArticle Title: #{@article.title}\nArticle Content: #{@article.body_markdown.to_s.first(1000)}\n\nReturn only the most relevant tag names as a comma-separated list, maximum 10 tags:"

      response = deliver_chat_result(prompt, system, 0.1)
      selected_names = parse_tag_names(response)

      # Return the actual tag objects for the selected names
      candidate_tags.where(name: selected_names).to_a
    end

    ##
    # Second pass: Use tag summaries to select final 2-4 tags.
    # @param top_ten_tags [Array<Tag>] Top 10 candidate tags.
    # @return [Array<String>] Final 2-4 tag names.
    def select_final_tags(top_ten_tags)
      # Build detailed tag information including summaries
      tag_details = top_ten_tags.map do |tag|
        summary = tag.short_summary.presence || "No summary available"
        "#{tag.name}: #{summary}"
      end.join("\n")

      system = "Act as a precise tag selector. Output only the final tag names as a comma-separated list (e.g. 'javascript,webdev') with no additional text. Select 2-4 most appropriate tags."
      prompt = "Given the following article content and detailed tag information, select the 2-4 most appropriate tags:\n\nArticle Title: #{@article.title}\nArticle Content: #{@article.body_markdown.to_s.first(750)}\n\nAvailable Tags with Descriptions:\n#{tag_details}\n\nGuidelines:\n- The 'discuss' tag should be used for conversation starters\n- The 'watercooler' tag for non-software development topics\n- Use 'career' and 'productivity' when relevant\n- Use specific technology tags (javascript, ruby, etc.) when on topic\n- Only select tags that are truly relevant\n- If content is offensive, negative, or poorly written, return empty string\n\nReturn only the most appropriate 2-4 tag names as a comma-separated list:"

      response = deliver_chat_result(prompt, system, 0.1)
      parse_tag_names(response)
    end

    ##
    # Parses tag names from AI response.
    # @param response [String] The AI response.
    # @return [Array<String>] Array of tag names.
    def parse_tag_names(response)
      return [] unless response&.strip&.present?

      # Split by comma and clean up tag names
      response.strip.split(",").map(&:strip).reject(&:blank?)
    end
  end
end
