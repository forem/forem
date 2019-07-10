namespace :sponsorships do
  desc "Migrate existing sponsorships data to the Sponsorship model"
  task migrate_data: :environment do
    ActiveRecord::Base.transaction do
      puts "Migrating organization data..."
      Organization.find_each do |org|
        next unless org.sponsorship_level

        org_admin = org.users.where(organization_memberships: { type_of_user: "admin" }).take!

        Sponsorship.create!(
          organization: org,
          user: org_admin,
          level: org.sponsorship_level,
          status: org.sponsorship_status,
          expires_at: org.sponsorship_expires_at,
          blurb_html: org.sponsorship_blurb_html,
          featured_number: org.sponsorship_featured_number,
          instructions: org.sponsorship_instructions,
          instructions_updated_at: org.sponsorship_instructions_updated_at,
          tagline: org.sponsorship_tagline,
          url: org.sponsorship_url,
        )

        puts "Migrated organization '#{org.name}'"
      end

      puts "Migrating Tag sponsorship data..."
      Tag.where.not(sponsor_organization_id: nil).includes(:sponsor_organization).find_each do |tag|
        org = tag.sponsor_organization

        org_admin = org.users.where(organization_memberships: { type_of_user: "admin" }).take!

        Sponsorship.create!(
          organization: org,
          user: org_admin,
          level: "tag",
          # when an org purchases a tag sponsorship, its status isn't set
          # so I ise tag.sponsorship_status (which was previously checked in app/views/tags/index.html.erb)
          status: tag.sponsorship_status,
          sponsorable: tag,
        )

        puts "Migrated tag '#{tag.name}' sponsorship by '#{org.name}'"
      end
    end

    puts "All done now!"
    puts "Sponsorships without any traceable info in the DB need to be created manually!"
  end
end
