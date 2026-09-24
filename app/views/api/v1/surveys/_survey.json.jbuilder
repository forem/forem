json.type_of "survey"

json.extract!(
  survey,
  :id,
  :title,
  :slug,
  :active,
  :display_title,
  :allow_resubmission,
  :daily_email_distributions,
  :extra_email_context_paragraph,
  :target_response_count
)
json.survey_type_of survey.type_of
json.target_completion_date survey.target_completion_date ? utc_iso_timestamp(survey.target_completion_date) : nil

json.created_at utc_iso_timestamp(survey.created_at)
json.updated_at utc_iso_timestamp(survey.updated_at)
