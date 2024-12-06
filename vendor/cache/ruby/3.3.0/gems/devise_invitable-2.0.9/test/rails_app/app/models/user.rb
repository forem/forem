class User < PARENT_MODEL_CLASS
  if DEVISE_ORM == :mongoid
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic if defined?(Mongoid::Attributes::Dynamic)

    ## Database authenticatable
    field :email,              type: String, default: ""
    field :encrypted_password, type: String, default: ""

    ## Recoverable
    field :reset_password_token,   type: String
    field :reset_password_sent_at, type: Time

    ## Confirmable
    field :confirmation_token,   type: String
    field :confirmed_at,         type: Time
    field :confirmation_sent_at, type: Time
    field :unconfirmed_email,    type: String # Only if using reconfirmable

    ## Invitable
    field :invitation_token,       type: String
    field :invitation_created_at,  type: Time
    field :invitation_sent_at,     type: Time
    field :invitation_accepted_at, type: Time
    field :invitation_limit,       type: Integer
    field :invited_by_id,          type: Integer
    field :invited_by_type,        type: String

    field :username
    field :profile_id
    field :active

    validates_presence_of :email
    validates_presence_of :encrypted_password, if: :password_required?
  end

  devise :database_authenticatable, :registerable, :validatable, :confirmable, :invitable, :recoverable

  attr_accessor :after_invitation_created_callback_works, :after_invitation_accepted_callback_works, :bio, :token
  validates :username, length: { maximum: 20 }

  attr_accessor :testing_accepted_or_not_invited

  validates :username, presence: true, if: :testing_accepted_or_not_invited_validator?
  validates :bio, presence: true, if: :invitation_accepted?

  def testing_accepted_or_not_invited_validator?
    testing_accepted_or_not_invited && accepted_or_not_invited?
  end

  after_invitation_created do |object|
    object.after_invitation_created_callback_works = true
  end

  after_invitation_accepted do |object|
    object.after_invitation_accepted_callback_works = true
  end

  def send_devise_notification(method, raw = nil, *args)
    Thread.current[:token] = raw
    super
  end
end
