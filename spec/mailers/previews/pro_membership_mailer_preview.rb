# Preview all emails at http://localhost:3000/rails/mailers/pro_membership_mailer
class ProMembershipMailerPreview < ActionMailer::Preview
  def expiring_membership
    pro_membership = ProMembership.find_or_create_by(user: User.last)
    ProMembershipMailer.expiring_membership(pro_membership, 1.week.from_now)
  end
end
