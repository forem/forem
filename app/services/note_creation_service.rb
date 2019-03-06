class NoteCreationService
  attr_reader :user, :admin

  def initialize(user, admin)
    @user = user
    @admin = admin
  end

  def create(reason, content)
    Note.create(
      author_id: @admin.id,
      noteable_id: @user.id,
      noteable_type: "User",
      reason: reason,
      content: content,
    )
  end
end
