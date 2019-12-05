require "rails_helper"

RSpec.describe TagAdjustment, type: :model do
  let_it_be(:article) { create(:article) }
  let_it_be(:admin_user) { create(:user, :admin) }
  let_it_be(:regular_user) { create(:user) }

  it { is_expected.to validate_presence_of(:user_id) }
  it { is_expected.to validate_presence_of(:article_id) }
  it { is_expected.to validate_presence_of(:tag_id) }
  it { is_expected.to validate_presence_of(:tag_name) }
  it { is_expected.to validate_presence_of(:adjustment_type) }
  it { is_expected.to validate_inclusion_of(:adjustment_type).in_array(%w[removal addition]) }
  it { is_expected.to validate_presence_of(:status) }

  it do
    # rubocop:disable RSpec/NamedSubject
    expect(subject).to validate_inclusion_of(:status).in_array(
      %w[committed pending committed_and_resolvable resolved],
    )
    # rubocop:enable RSpec/NamedSubject
  end

  it { is_expected.to have_many(:notifications).dependent(:delete_all) }

  describe "validations" do
    let(:tag) { create(:tag) }
    let(:mod_user) { create(:user) }

    describe "privileges" do
      before do
        mod_user.add_role(:tag_moderator, tag)
      end

      it "allows tag mods to create for their tags" do
        tag_adjustment = build(:tag_adjustment, user: mod_user, article: article, tag: tag)
        expect(tag_adjustment).to be_valid
      end

      it "does not allow tag mods to create for other tags" do
        another_tag = create(:tag)
        tag_adjustment = build(:tag_adjustment, user: mod_user, article: article, tag: another_tag)
        expect(tag_adjustment).to be_invalid
      end

      it "allows admins to create for any tags" do
        tag_adjustment = build(:tag_adjustment, user: admin_user, article: article, tag: tag)
        expect(tag_adjustment).to be_valid
      end

      it "does not allow normal users to create for any tags" do
        tag_adjustment = build(:tag_adjustment, user: regular_user, article: article, tag: tag)
        expect(tag_adjustment).to be_invalid
      end
    end
  end
end
