json.array! @surveys do |survey|
  json.partial! "api/v1/surveys/survey", survey: survey
end
