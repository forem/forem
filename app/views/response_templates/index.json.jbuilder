attrs = %i[id type_of user_id title content]

if @response_templates.is_a?(Array)
  json.array!(@response_templates, *attrs)
else
  @response_templates.each_pair do |type_of, templates|
    json.set!(type_of) do
      json.array!(templates, *attrs)
    end
  end
end
