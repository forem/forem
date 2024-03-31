class CreatorSettingsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :checked_code_of_conduct, :boolean, default: false
  attribute :checked_terms_and_conditions, :boolean, default: false
  attribute :community_name, :string
  attribute :invite_only_mode, :boolean
  attribute :logo
  attribute :primary_brand_color_hex, :string
  attribute :public, :boolean

  validates :community_name, :primary_brand_color_hex, presence: true

  validates :checked_code_of_conduct, inclusion: { in: [true, false] }
  validates :checked_terms_and_conditions, inclusion: { in: [true, false] }
  validates :invite_only_mode, inclusion: { in: [true, false] }
  validates :public, inclusion: { in: [true, false] }

  attr_accessor :success

  def save
    ::Settings::Community.community_name = community_name
    ::Settings::UserExperience.primary_brand_color_hex = primary_brand_color_hex
    ::Settings::Authentication.invite_only_mode = invite_only_mode
    ::Settings::UserExperience.public = public

    if logo
      logo_uploader = upload_logo(logo)
      ::Settings::General.original_logo = logo_uploader.url
      ::Settings::General.resized_logo = logo_uploader.resized_logo.url
    end
    @success = true
  rescue StandardError => e
    errors.add(:base, e.message)
    @success = false
  end

  private

  def upload_logo(image)
    LogoUploader.new.tap do |uploader|
      uploader.store!(image)
    end
  end
end
