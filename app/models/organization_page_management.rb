# Rolify resource for the "Resource Admin: OrganizationPageManagement" role. Its holders manage the
# pages of any organization with org_readme enabled through Api::V1::PagesController, without being a
# member. Nothing else checks it: it grants no admin area, no Organization or Page resource access, and
# never makes User#org_admin? true.
# NOTE: It is not backed by a database table and should not be expected to function like a
# traditional Rails model.
class OrganizationPageManagement < ApplicationRecord
  resourcify
end
