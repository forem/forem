module ProfileFields
  class AddCodingFields
    include FieldDefinition

    field "Skills/Languages", :text_area, description: <<~DESCRIPTION
      What tools and languages are you most experienced with? Are you specialized or more of a generalist?
    DESCRIPTION

    field "I'm getting into", :text_area, description: <<~DESCRIPTION
      What are you learning right now? What are the new tools and languages you're picking up right now?
    DESCRIPTION

    field "My projects and hacks", :text_area, description: <<~DESCRIPTION
      What projects are currently occupying most of your time?
    DESCRIPTION

    field "Available for", :text_area, description: <<~DESCRIPTION
      What kinds of collaborations or discussions are you available for? What's a good reason to say Hey! to you these days?
    DESCRIPTION
  end
end
