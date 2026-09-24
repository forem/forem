module Ai
  class SurveyContextGenerator
    VERSION = "1.0"

    # @param survey [Survey] The survey to generate email context for.
    def initialize(survey)
      @survey = survey
      @ai_client = Ai::Base.new(wrapper: self, affected_content: (survey.persisted? ? survey : nil))
    end

    # Calls the Gemini API to generate the email context paragraph.
    # @return [String, nil]
    def call
      prompt = build_prompt
      return if prompt.blank?

      response = @ai_client.call(prompt)
      response&.strip
    rescue StandardError => e
      Rails.logger.error("Survey Context Generation failed: #{e.message}")
      nil
    end

    private

    # Builds the prompt for the Gemini API using the template and the survey content.
    # @return [String]
    def build_prompt
      polls = @survey.polls.reject(&:marked_for_destruction?)
      poll_count = polls.size
      polls_list = polls.map.with_index(1) do |poll, i|
        "Question #{i}: #{poll.prompt_markdown}"
      end.join("\n")

      <<~PROMPT
        You are an AI assistant that generates a simple introductory email message for a user survey.

        Generate a single-sentence message describing this survey.
        The message MUST look very similar to this template:
        This is *very quick* {number_of_questions}-question private survey to understand {topic_of_the_survey}

        Please replace {number_of_questions} with the actual number of questions in words (e.g. "four" if 4, "three" if 3, "one" if 1, etc.) and {topic_of_the_survey} with a concise summary of what the survey aims to understand.
        Do not add any greeting, signature, introduction, other sentences, or quotation marks. Return ONLY the generated sentence.

        Context of the survey:
        - Title: #{@survey.title}
        - Number of questions: #{poll_count}
        - Survey Questions:
        #{polls_list}
      PROMPT
    end
  end
end
