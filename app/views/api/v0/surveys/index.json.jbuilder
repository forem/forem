json.array! @surveys do |survey|
  json.partial! "api/v0/surveys/survey", survey: survey
end
