module Ai
  class ForemTags
    def initialize(subforem_id, brain_dump)
      @subforem_id = subforem_id
      @brain_dump = brain_dump
      @subforem = Subforem.find(subforem_id)
    end

    def upsert!
      generate_tags
    rescue StandardError => e
      Rails.logger.error("Failed to upsert Forem tags: #{e.message}")
    end

    private

    def generate_tags
      prompt = <<~PROMPT
                  Generate 100 tags for the subforem with domain #{@subforem.domain} based on the following brain dump: #{@brain_dump}.
                  The tags should be relevant to the community's focus and interests.
                  Please output the tags as a line-break-separated list with each line representing the tag and a short description after a colon,
                  example:

                  webdev: Web development topics including HTML, CSS, JavaScript, and frameworks.
                  cryptocurrency: Discussions about cryptocurrencies, blockchain technology, and related financial topics.
                  career: Career advice, job searching tips, and professional development.
                  ruby: Ruby programming language discussions, tutorials, and resources.
                  tutorial: Tutorials and guides on various topics relevant to the community.

                  The tags should be only letters like the above. No numbers, special characters, underscores etc.
      
                  Please provide a list that adequately covers the community's interests without being too broad or too narrow.
                  Provide 100 tags in the EXACT format specified above. Do not include any additional text or explanations.
               PROMPT
      response = Ai::Base.new.call(prompt)
      tags = response.split("\n").map do |line|
        tag, description = line.split(":", 2).map(&:strip)
        { name: tag, description: description }
      end

      # Upsert tags into the database
      tags.each do |tag|
        tag = Tag.where(name: tag[:name]).first
        if tag && tag.short_summary.blank?
          tag.short_summary = tag[:description]
          tag.save!
        elsif tag.nil?
          tag = Tag.create(name: tag[:name], short_summary: tag[:description])
        end

        TagSubforemRelationship.create(
          subforem_id: @subforem_id,
          tag_id: tag.id,
          supported: true
        )
      end
    rescue StandardError => e
      Rails.logger.error("Failed to generate Forem tags: #{e.message}")
    end
  end
end