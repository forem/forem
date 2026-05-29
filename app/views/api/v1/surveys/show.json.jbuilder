json.partial! "api/v1/surveys/survey", survey: @survey

json.polls @survey.polls.includes(:poll_options) do |poll|
  json.type_of "poll"
  json.extract!(
    poll,
    :id,
    :prompt_markdown,
    :prompt_html,
    :position,
    :poll_votes_count,
    :poll_skips_count,
    :poll_options_count,
    :scale_min,
    :scale_max
  )
  json.poll_type_of poll.type_of
  json.created_at utc_iso_timestamp(poll.created_at)
  json.updated_at utc_iso_timestamp(poll.updated_at)

  json.poll_options poll.poll_options do |option|
    json.type_of "poll_option"
    json.extract!(
      option,
      :id,
      :markdown,
      :processed_html,
      :position,
      :poll_votes_count,
      :supplementary_text
    )
  end
end
