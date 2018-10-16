class MentorRelationship < ApplicationRecord
  belongs_to :mentor, class_name: "User"
  belongs_to :mentee, class_name: "User"
  validates :mentor, presence: true
  validates :mentee, presence: true
  validate :check_for_same_user
  validates_uniqueness_of :mentor_id, scope: :mentee_id

  after_create :mutual_follow
  after_create :send_emails

  def check_for_same_user
    if mentor_id == mentee_id
      errors.add(:mentor_relationship, "Mentor and Mentee cannot be the same person")
    end
  end

  def self.unmatched_mentees
    sql = "SELECT mentee_form_updated_at,
       users.id,
       mentor_relationships.mentor_id
    FROM users
    LEFT JOIN notes ON users.id = notes.noteable_id
    LEFT JOIN mentor_relationships ON users.id = mentor_relationships.mentee_id
    WHERE seeking_mentorship IS TRUE
    AND mentor_relationships.mentor_id IS null"
    record_ids = ActiveRecord::Base.connection.execute(sql).pluck("id")
    User.where(id: record_ids)
  end

  def self.unmatched_mentors
    sql = "SELECT mentor_form_updated_at,
       users.id,
       mentor_relationships.mentor_id
    FROM users
    LEFT JOIN notes ON users.id = notes.noteable_id
    LEFT JOIN mentor_relationships ON users.id = mentor_relationships.mentor_id
    WHERE offering_mentorship IS TRUE
    AND mentor_relationships.mentee_id IS null"
    record_ids = ActiveRecord::Base.connection.execute(sql).pluck("id")
    User.where(id: record_ids)
  end


  private

  def mutual_follow
    mentor.follow(mentee)
    mentee.follow(mentor)
  end

  def send_emails
    NotifyMailer.mentee_email(mentee, mentor).deliver
    NotifyMailer.mentor_email(mentor, mentee).deliver
  end
end
