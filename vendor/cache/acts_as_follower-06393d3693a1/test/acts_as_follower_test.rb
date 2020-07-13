require File.dirname(__FILE__) + '/test_helper'

class ActsAsFollowerTest < ActiveSupport::TestCase

  context "instance methods" do
    setup do
      @sam = FactoryGirl.create(:sam)
    end

    should "be defined" do
      assert @sam.respond_to?(:following?)
      assert @sam.respond_to?(:follow_count)
      assert @sam.respond_to?(:follow)
      assert @sam.respond_to?(:stop_following)
      assert @sam.respond_to?(:follows_by_type)
      assert @sam.respond_to?(:all_follows)
    end
  end

  context "acts_as_follower" do
    setup do
      @sam = FactoryGirl.create(:sam)
      @jon = FactoryGirl.create(:jon)
      @oasis = FactoryGirl.create(:oasis)
      @sam.follow(@jon)
      @sam.follow(@oasis)
    end

    context "following" do
      should "return following_status" do
        assert_equal true, @sam.following?(@jon)
        assert_equal false, @jon.following?(@sam)
      end

      should "return follow_count" do
        assert_equal 2, @sam.follow_count
        assert_equal 0, @jon.follow_count
      end
    end

    context "follow a friend" do
      setup do
        @jon.follow(@sam)
      end

      should_change("Follow count", by: 1) { Follow.count }
      should_change("@jon.follow_count", by: 1) { @jon.follow_count }

      should "set the follower" do
        assert_equal @jon, Follow.last.follower
      end

      should "set the followable" do
        assert_equal @sam, Follow.last.followable
      end
    end

    context "follow yourself" do
      setup do
        @jon.follow(@jon)
      end

      should_not_change("Follow count") { Follow.count }
      should_not_change("@jon.follow_count") { @jon.follow_count }

      should "not set the follower" do
        assert_not_equal @jon, Follow.last.follower
      end

      should "not set the followable" do
        assert_not_equal @jon, Follow.last.followable
      end
    end

    context "stop_following" do
      setup do
        @sam.stop_following(@jon)
      end

      should_change("Follow count", by: -1) { Follow.count }
      should_change("@sam.follow_count", by: -1) { @sam.follow_count }
    end

    context "follows" do
      setup do
        @band_follow = Follow.where("follower_id = ? and follower_type = 'User' and followable_id = ? and followable_type = 'Band'", @sam.id, @oasis.id).first
        @user_follow = Follow.where("follower_id = ? and follower_type = 'User' and followable_id = ? and followable_type = 'User'", @sam.id, @jon.id).first
      end

      context "follows_by_type" do
        should "only return requested follows" do
          assert_equal [@band_follow], @sam.follows_by_type('Band')
          assert_equal [@user_follow], @sam.follows_by_type('User')
        end

        should "accept AR options" do
          @metallica = FactoryGirl.create(:metallica)
          @sam.follow(@metallica)
          assert_equal 1, @sam.follows_by_type('Band', limit: 1).count
        end
      end

      context "following_by_type_count" do
        should "return the count of the requested type" do
          @metallica = FactoryGirl.create(:metallica)
          @sam.follow(@metallica)
          assert_equal 2, @sam.following_by_type_count('Band')
          assert_equal 1, @sam.following_by_type_count('User')
          assert_equal 0, @jon.following_by_type_count('Band')
          @jon.block(@sam)
          assert_equal 0, @sam.following_by_type_count('User')
        end
      end

      context "all_follows" do
        should "return all follows" do
          assert_equal 2, @sam.all_follows.size
          assert @sam.all_follows.include?(@band_follow)
          assert @sam.all_follows.include?(@user_follow)
          assert_equal [], @jon.all_follows
        end

        should "accept AR options" do
          assert_equal 1, @sam.all_follows(limit: 1).count
        end
      end
    end

    context "all_following" do
      should "return the actual follow records" do
        assert_equal 2, @sam.all_following.size
        assert @sam.all_following.include?(@oasis)
        assert @sam.all_following.include?(@jon)
        assert_equal [], @jon.all_following
      end

      should "accept AR limit option" do
        assert_equal 1, @sam.all_following(limit: 1).count
      end

      should "accept AR where option" do
        assert_equal 1, @sam.all_following(where: { id: @oasis.id }).count
      end
    end

    context "following_by_type" do
      should "return only requested records" do
        assert_equal [@oasis], @sam.following_by_type('Band')
        assert_equal [@jon], @sam.following_by_type('User')
      end

      should "accept AR options" do
        @metallica = FactoryGirl.create(:metallica)
        @sam.follow(@metallica)
        assert_equal 1, @sam.following_by_type('Band', limit: 1).to_a.size
      end
    end

    context "method_missing" do
      should "call following_by_type" do
        assert_equal [@oasis], @sam.following_bands
        assert_equal [@jon], @sam.following_users
      end

      should "call following_by_type_count" do
        @metallica = FactoryGirl.create(:metallica)
        @sam.follow(@metallica)
        assert_equal 2, @sam.following_bands_count
        assert_equal 1, @sam.following_users_count
        assert_equal 0, @jon.following_bands_count
        @jon.block(@sam)
        assert_equal 0, @sam.following_users_count
      end

      should "raise on no method" do
        assert_raises (NoMethodError){ @sam.foobar }
      end
    end

    context "respond_to?" do
      should "advertise that it responds to following methods" do
        assert @sam.respond_to?(:following_users)
        assert @sam.respond_to?(:following_users_count)
      end

      should "return false when called with a nonexistent method" do
        assert (not @sam.respond_to?(:foobar))
      end
    end

    context "destroying follower" do
      setup do
        @jon.destroy
      end

      should_change("Follow.count", by: -1) { Follow.count }
      should_change("@sam.follow_count", by: -1) { @sam.follow_count }
    end

    context "blocked by followable" do
      setup do
        @jon.block(@sam)
      end

      should "return following_status" do
        assert_equal false, @sam.following?(@jon)
      end

      should "return follow_count" do
        assert_equal 1, @sam.follow_count
      end

      should "not return record of the blocked follows" do
        assert_equal 1, @sam.all_follows.size
        assert !@sam.all_follows.include?(@user_follow)
        assert !@sam.all_following.include?(@jon)
        assert_equal [], @sam.following_by_type('User')
        assert_equal [], @sam.follows_by_type('User')
        assert_equal [], @sam.following_users
      end
    end
  end

end
