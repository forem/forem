class CreatorSettingsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :community_name, :string
  attribute :primary_brand_color_hex, :string
  # [TODO]: add some more attributes here

  validates :community_name, :primary_brand_color_hex, :invite_only_mode, :public, :checked_code_of_conduct,
            :checked_terms_and_conditions, presence: true
  # maybe we validate the contrast color here?

  attr_accessor :community_name, :primary_brand_color_hex, :invite_only_mode, :public, :logo,
                :checked_code_of_conduct, :checked_terms_and_conditions

  def initialize(community_name:, primary_brand_color_hex:, invite_only_mode:, public:,
                 checked_code_of_conduct:, checked_terms_and_conditions:, logo: nil)
    @community_name = community_name
    @primary_brand_color_hex = primary_brand_color_hex
    @invite_only_mode = invite_only_mode
    @public = public
    @logo = logo
    @checked_code_of_conduct = checked_code_of_conduct
    @checked_terms_and_conditions = checked_terms_and_conditions
  end

  def save
    return false unless valid?

    ::Settings::Community.community_name = @community_name
    ::Settings::UserExperience.primary_brand_color_hex = @primary_brand_color_hex
    ::Settings::Authentication.invite_only_mode = @invite_only
    ::Settings::UserExperience.public = @public

    return unless @logo

    logo_uploader = upload_logo(@logo)
    ::Settings::General.original_logo = logo_uploader.url
    ::Settings::General.resized_logo = logo_uploader.resized_logo.url
  end

  private

  def upload_logo(image)
    LogoUploader.new.tap do |uploader|
      uploader.store!(image)
    end
  end
end
