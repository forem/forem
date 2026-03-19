json.type_of "survey"

json.extract!(
  survey,
  :id,
  :title,
  :slug,
  :active,
  :display_title,
  :allow_resubmission
)
json.survey_type_of survey.type_of

json.created_at utc_iso_timestamp(survey.created_at)
json.updated_at utc_iso_timestamp(survey.updated_at)
