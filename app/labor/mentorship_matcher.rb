module MentorshipMatcher
  def self.match_mentees_and_mentors(mentee_ids, mentor_ids)
    mentee_ids.each_with_index do |id, index|
      mentor = User.find(mentor_ids[index])
      MentorRelationship.create(mentee_id: id, mentor_id: mentor.id)
    end
  end
end
