class OrganizationForm < YAAF::Form
  include ImageUploads

  attr_accessor :organization_attributes, :organization_membership, :current_user
  after_save :create_organization_membership
  validate :validate_image

  def initialize(attributes)
    super(attributes)
    @models = [organization]
  end

  def organization
    @organization ||= if organization_attributes["id"].present?
                        Organization.find(organization_attributes["id"]).tap do |model|
                          model.assign_attributes(organization_attributes)
                        end
                      else
                        Organization.new(organization_attributes)
                      end
  end

  def create_organization_membership
    return unless organization.new_record?

    @organization_membership = OrganizationMembership.create!(organization: @organization,
                                                              user: current_user,
                                                              type_of_user: "admin")
  end

  private

  def validate_image
    return if valid_image_file?

    valid_filename?
  end

  def valid_image_file?
    return true if file?(organization_attributes["profile_image"])

    organization.errors.add(:profile_image, IS_NOT_FILE_MESSAGE)
  end

  def valid_filename?
    return true unless long_filename?(organization_attributes["profile_image"])

    organization.errors.add(:profile_image, FILENAME_TOO_LONG_MESSAGE)
  end
end
