class AddSurveyRefernceToPolls < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :polls, :survey, null: true, index: {algorithm: :concurrently}
  end
end


s = Survey.create!(title: "Default Survey", active: true, display_title: true)
Poll.create(prompt_markdown: "Default Poll", article_id: nil, survey_id: s.id, poll_options_input_array: ["Option 1", "Option 2"])
Poll.create(prompt_markdown: "Another Poll", article_id: nil, survey_id: s.id, poll_options_input_array: ["Choice A", "Choice B"])
Poll.create(prompt_markdown: "Third Poll", article_id: nil, survey_id: s.id, poll_options_input_array: ["Yes", "No"])
Poll.create(prompt_markdown: "Fourth Poll", article_id: nil, survey_id: s.id, poll_options_input_array: ["Agree", "Disagree"])