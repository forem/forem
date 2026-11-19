# Helpers for exercising the structured decision (TypeSafe Jev / Gemini Decision) path of AI functions
# (see Ai::FunctionConfig).
module JevHelpers
  # Selects Jev for the given AI functions and provides a fake TypeSafe key.
  def enable_jev_for(*function_keys)
    stub_const("Ai::TypeSafe::Client::DEFAULT_KEY", "test-typesafe-key")
    Settings::AiFunctions.set_global_function_models(function_keys.to_h { |key| [key.to_s, "jev"] })
  end

  # Selects Gemini Decision 1 for the given AI functions and provides a fake Gemini key.
  def enable_gemini_decision_for(*function_keys)
    stub_const("Ai::Base::DEFAULT_KEY", "test-gemini-key")
    Settings::AiFunctions.set_global_function_models(function_keys.to_h { |key| [key.to_s, "gemini_decision"] })
  end

  # Replaces Ai::TypeSafe::Client with a fake that answers every question actually sent.
  #
  DEFAULT_NOUL = 0.05

  # @param answers [Hash] question id => answer, as a hash or keywords. Nouls take a
  #   probability, Scores a position (0..levels-1), Choices an [option, confidence] pair.
  #   Unlisted Nouls get DEFAULT_NOUL, Scores 0.0, and Choices their first option.
  # @yieldparam state [Object] With a block, answers are computed per request from its state.
  # @return [Array<Hash>] The requests sent, each with :state and :questions.
  def stub_jev(answers = {}, **keyword_answers, &per_request)
    stub_decision_client(Ai::TypeSafe::Client, "jev-1.13.0", answers, **keyword_answers, &per_request)
  end

  # Replaces Ai::GeminiDecision::Client with a fake that answers every question actually sent.
  def stub_gemini_decision(answers = {}, **keyword_answers, &per_request)
    stub_decision_client(Ai::GeminiDecision::Client, "gemini-decision-1", answers, **keyword_answers, &per_request)
  end

  private

  def stub_decision_client(client_class, model_name, answers = {}, **keyword_answers)
    fixed_answers = answers.merge(keyword_answers)
    requests = []
    client = instance_double(client_class)
    allow(client_class).to receive(:new).and_return(client)
    allow(client).to receive(:evaluate) do |state:, questions:|
      requests << { state: state, questions: questions }
      request_answers = block_given? ? yield(state) : fixed_answers
      Ai::TypeSafe::Result.new(
        "model" => model_name,
        "answers" => fake_jev_answers(questions, request_answers.transform_keys(&:to_s)),
      )
    end
    requests
  end

  def fake_jev_answers(questions, answers)
    questions.to_h do |id, question|
      override = answers[id.to_s]
      answer = case question[:type]
               when "noul" then { "type" => "noul", "noul" => override || DEFAULT_NOUL }
               when "score" then fake_score_answer(question, override || 0.0)
               when "choice" then fake_choice_answer(question, override)
               else raise ArgumentError, "Unknown question type #{question[:type].inspect} for #{id}"
               end
      [id.to_s, answer]
    end
  end

  def fake_score_answer(question, position)
    levels = question[:criteria].size
    raise ArgumentError, "Score position #{position} outside 0..#{levels - 1}" unless position.between?(0, levels - 1)

    {
      "type" => "score",
      "score" => position,
      "legend" => (0...levels).to_h { |index| [index.to_s, question[:criteria][index].to_s] },
      "probabilities" => (0...levels).to_h { |index| [index.to_s, index == position.round ? 1.0 : 0.0] },
      "confidence" => 1.0
    }
  end

  def fake_choice_answer(question, override)
    chosen, confidence = override || [question[:criteria].keys.first, 1.0]
    raise ArgumentError, "#{chosen} is not an option" unless question[:criteria].key?(chosen)

    { "type" => "choice", "choice" => chosen, "probabilities" => { chosen => confidence }, "confidence" => confidence }
  end
end
