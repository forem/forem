module ProfileFields
  class AddCodingFields < AddFields
    field "Skills/Languages", :text_area, explanation: <<~EXPLANATION
      What tools and languages are you most experienced with? Are you specialized or more of a generalist?
    EXPLANATION

    field "I'm getting into", :text_area, explanation: <<~EXPLANATION
      What are you learning right now? What are the new tools and languages you're picking up right now?
    EXPLANATION

    field "My projects and hacks", :text_area, explanation: <<~EXPLANATION
      What projects are currently occupying most of your time?
    EXPLANATION

    field "Available for", :text_area, explanation: <<~EXPLANATION
      What kinds of collaborations or discussions are you available for? What's a good reason to say Hey! to you these days?
    EXPLANATION
  end
end
