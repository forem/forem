# Preview all emails at http://localhost:3000/rails/mailers/digest_mailer
class DigestMailerPreview < ActionMailer::Preview
  def digest_email
    user = User.last
    tags = user.cached_followed_tag_names&.first(12)
    first_billboard = Billboard.for_display(area: "digest_first",
                                            user_id: user.id,
                                            user_tags: tags,
                                            user_signed_in: true)
    second_billboard = Billboard.for_display(area: "digest_second",
                                             user_id: user.id,
                                             user_tags: tags,
                                             user_signed_in: true)
    DigestMailer.with(user: user, articles: Article.all, billboards: [first_billboard, second_billboard]).digest_email
  end
end
