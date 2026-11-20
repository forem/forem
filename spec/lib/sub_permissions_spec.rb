require "rails_helper"

RSpec.describe SubPermissions do
  let(:user) { create(:user) }

  def grant_row(user, resource_type)
    role = Role.find_by(name: "single_resource_admin", resource_type: resource_type, resource_id: nil)
    UserRole.find_by(user_id: user.id, role_id: role.id)
  end

  describe "CLAUSES" do
    it "only registers resource types admins can grant single_resource_admin on" do
      grantable = Constants::Role::SPECIAL_ROLES_LABELS_TO_WHERE_CLAUSE.values
        .select { |where| where.is_a?(Hash) && where[:name] == "single_resource_admin" }
        .pluck(:resource_type)

      expect(grantable).to include(*described_class::CLAUSES.keys)
    end

    it "registers lowercase snake_case clause names with labels and descriptions in every locale",
       :aggregate_failures do
      described_class::CLAUSES.each do |resource_type, clauses|
        I18n.available_locales.each do |locale|
          expect(I18n.exists?("lib.sub_permissions.baseline_hints.#{resource_type.underscore}", locale))
            .to be(true), "#{locale} is missing baseline hint for #{resource_type}"
        end

        clauses.each do |clause|
          expect(clause).to match(/\A[a-z][a-z_]*\z/)
          I18n.available_locales.each do |locale|
            expect(I18n.exists?("lib.sub_permissions.clauses.#{resource_type.underscore}.#{clause}", locale))
              .to be(true), "#{locale} is missing #{resource_type} #{clause}"
            desc_key = "lib.sub_permissions.clause_descriptions.#{resource_type.underscore}.#{clause}"
            expect(I18n.exists?(desc_key, locale))
              .to be(true), "#{locale} is missing description for #{resource_type} #{clause}"
          end
        end
      end
    end
  end

  describe ".build" do
    it "normalizes the allow list" do
      expect(described_class.build(allow: [:publish, "approve", "publish"]))
        .to eq({ "version" => 1, "allow" => %w[approve publish] })
    end
  end

  describe ".update_grant" do
    before { user.add_role(:single_resource_admin, Billboard) }

    it "stores the configuration on the user's grant only" do
      other = create(:user)
      other.add_role(:single_resource_admin, Billboard)

      result = described_class.update_grant(user: user, resource_type: "Billboard",
                                            sub_permissions: described_class.build(allow: %w[approve]))

      expect(result).to be_success
      expect(grant_row(user, "Billboard").sub_permissions).to eq({ "version" => 1, "allow" => %w[approve] })
      expect(grant_row(other, "Billboard").sub_permissions).to be_nil
    end

    it "clears the configuration with nil, restoring full access" do
      described_class.update_grant(user: user, resource_type: "Billboard",
                                   sub_permissions: described_class.build(allow: []))
      result = described_class.update_grant(user: user, resource_type: "Billboard", sub_permissions: nil)

      expect(result).to be_success
      expect(grant_row(user, "Billboard").sub_permissions).to be_nil
    end

    it "refuses an invalid configuration and leaves the grant unchanged", :aggregate_failures do
      result = described_class.update_grant(user: user, resource_type: "Billboard",
                                            sub_permissions: { "version" => 1, "allow" => %w[everything] })

      expect(result).not_to be_success
      expect(result.errors.first).to include("everything")
      expect(grant_row(user, "Billboard").sub_permissions).to be_nil
    end

    it "refuses a resource type without sub-permissions" do
      user.add_role(:single_resource_admin, Article)
      result = described_class.update_grant(user: user, resource_type: "Article",
                                            sub_permissions: described_class.build(allow: []))

      expect(result).not_to be_success
      expect(grant_row(user, "Article").sub_permissions).to be_nil
    end

    it "restricts the user's grants on every matching class-wide role row" do
      duplicate_role = Role.create!(name: "single_resource_admin", resource_type: "Billboard")
      UserRole.create!(user: user, role: duplicate_role)

      described_class.update_grant(user: user, resource_type: "Billboard",
                                   sub_permissions: described_class.build(allow: []))

      expect(UserRole.where(user_id: user.id).pluck(:sub_permissions)).to all(eq({ "version" => 1, "allow" => [] }))
      expect(user.reload.sub_permission?(resource: Billboard, clause: "approve")).to be(false)
    end

    it "reports failure, not success, when the update matches no grant row" do
      revoked = create(:user)
      revoked.add_role(:single_resource_admin, Billboard)
      revoked.remove_role(:single_resource_admin, Billboard)

      result = described_class.update_grant(user: revoked, resource_type: "Billboard",
                                            sub_permissions: described_class.build(allow: []))

      expect(result).not_to be_success
      expect(UserRole.where(user_id: revoked.id)).to be_empty
    end

    it "refuses a user without the grant" do
      result = described_class.update_grant(user: create(:user), resource_type: "Billboard",
                                            sub_permissions: described_class.build(allow: []))

      expect(result).not_to be_success
    end

    it "keeps the restriction when rolify is asked to grant the role again" do
      described_class.update_grant(user: user, resource_type: "Billboard",
                                   sub_permissions: described_class.build(allow: []))
      user.add_role(:single_resource_admin, Billboard)

      expect(UserRole.where(user_id: user.id).pluck(:sub_permissions)).to eq([{ "version" => 1, "allow" => [] }])
    end

    it "drops the restriction with the grant when the role is revoked" do
      described_class.update_grant(user: user, resource_type: "Billboard",
                                   sub_permissions: described_class.build(allow: []))
      user.remove_role(:single_resource_admin, Billboard)
      user.add_role(:single_resource_admin, Billboard)

      expect(grant_row(user, "Billboard").sub_permissions).to be_nil
    end
  end
end
