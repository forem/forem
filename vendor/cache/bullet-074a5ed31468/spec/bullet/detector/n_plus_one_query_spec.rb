# frozen_string_literal: true

require 'spec_helper'

module Bullet
  module Detector
    describe NPlusOneQuery do
      before(:all) do
        @post = Post.first
        @post2 = Post.last
      end

      context '.call_association' do
        it 'should add call_object_associations' do
          expect(NPlusOneQuery).to receive(:add_call_object_associations).with(@post, :associations)
          NPlusOneQuery.call_association(@post, :associations)
        end
      end

      context '.possible?' do
        it 'should be true if possible_objects contain' do
          NPlusOneQuery.add_possible_objects(@post)
          expect(NPlusOneQuery.possible?(@post)).to eq true
        end
      end

      context '.impossible?' do
        it 'should be true if impossible_objects contain' do
          NPlusOneQuery.add_impossible_object(@post)
          expect(NPlusOneQuery.impossible?(@post)).to eq true
        end
      end

      context '.association?' do
        it 'should be true if object, associations pair is already existed' do
          NPlusOneQuery.add_object_associations(@post, :association)
          expect(NPlusOneQuery.association?(@post, :association)).to eq true
        end

        it 'should be false if object, association pair is not existed' do
          NPlusOneQuery.add_object_associations(@post, :association1)
          expect(NPlusOneQuery.association?(@post, :associatio2)).to eq false
        end
      end

      context '.conditions_met?' do
        it 'should be true if object is possible, not impossible and object, associations pair is not already existed' do
          allow(NPlusOneQuery).to receive(:possible?).with(@post).and_return(true)
          allow(NPlusOneQuery).to receive(:impossible?).with(@post).and_return(false)
          allow(NPlusOneQuery).to receive(:association?).with(@post, :associations).and_return(false)
          expect(NPlusOneQuery.conditions_met?(@post, :associations)).to eq true
        end

        it 'should be false if object is not possible, not impossible and object, associations pair is not already existed' do
          allow(NPlusOneQuery).to receive(:possible?).with(@post).and_return(false)
          allow(NPlusOneQuery).to receive(:impossible?).with(@post).and_return(false)
          allow(NPlusOneQuery).to receive(:association?).with(@post, :associations).and_return(false)
          expect(NPlusOneQuery.conditions_met?(@post, :associations)).to eq false
        end

        it 'should be false if object is possible, but impossible and object, associations pair is not already existed' do
          allow(NPlusOneQuery).to receive(:possible?).with(@post).and_return(true)
          allow(NPlusOneQuery).to receive(:impossible?).with(@post).and_return(true)
          allow(NPlusOneQuery).to receive(:association?).with(@post, :associations).and_return(false)
          expect(NPlusOneQuery.conditions_met?(@post, :associations)).to eq false
        end

        it 'should be false if object is possible, not impossible and object, associations pair is already existed' do
          allow(NPlusOneQuery).to receive(:possible?).with(@post).and_return(true)
          allow(NPlusOneQuery).to receive(:impossible?).with(@post).and_return(false)
          allow(NPlusOneQuery).to receive(:association?).with(@post, :associations).and_return(true)
          expect(NPlusOneQuery.conditions_met?(@post, :associations)).to eq false
        end
      end

      context '.call_association' do
        it 'should create notification if conditions met' do
          expect(NPlusOneQuery).to receive(:conditions_met?).with(@post, :association).and_return(true)
          expect(NPlusOneQuery).to receive(:caller_in_project).and_return(%w[caller])
          expect(NPlusOneQuery).to receive(:create_notification).with(%w[caller], 'Post', :association)
          NPlusOneQuery.call_association(@post, :association)
        end

        it 'should not create notification if conditions not met' do
          expect(NPlusOneQuery).to receive(:conditions_met?).with(@post, :association).and_return(false)
          expect(NPlusOneQuery).not_to receive(:caller_in_project!)
          expect(NPlusOneQuery).not_to receive(:create_notification).with('Post', :association)
          NPlusOneQuery.call_association(@post, :association)
        end

        context 'stacktrace_excludes' do
          before { Bullet.stacktrace_excludes = [/def/] }
          after { Bullet.stacktrace_excludes = nil }

          it 'should not create notification when stacktrace contains paths that are in the exclude list' do
            in_project = OpenStruct.new(absolute_path: File.join(Dir.pwd, 'abc', 'abc.rb'))
            included_path = OpenStruct.new(absolute_path: '/ghi/ghi.rb')
            excluded_path = OpenStruct.new(absolute_path: '/def/def.rb')

            expect(NPlusOneQuery).to receive(:caller_locations).and_return([in_project, included_path, excluded_path])
            expect(NPlusOneQuery).to_not receive(:create_notification)
            NPlusOneQuery.call_association(@post, :association)
          end

          # just a sanity spec to make sure the following spec works correctly
          it "should create notification when stacktrace contains methods that aren't in the exclude list" do
            method = NPlusOneQuery.method(:excluded_stacktrace_path?).source_location
            in_project = OpenStruct.new(absolute_path: File.join(Dir.pwd, 'abc', 'abc.rb'))
            excluded_path = OpenStruct.new(absolute_path: method.first, lineno: method.last)

            expect(NPlusOneQuery).to receive(:caller_locations).at_least(1).and_return([in_project, excluded_path])
            expect(NPlusOneQuery).to receive(:conditions_met?).and_return(true)
            expect(NPlusOneQuery).to receive(:create_notification)
            NPlusOneQuery.call_association(@post, :association)
          end

          it 'should not create notification when stacktrace contains methods that are in the exclude list' do
            method = NPlusOneQuery.method(:excluded_stacktrace_path?).source_location
            Bullet.stacktrace_excludes = [method]
            in_project = OpenStruct.new(absolute_path: File.join(Dir.pwd, 'abc', 'abc.rb'))
            excluded_path = OpenStruct.new(absolute_path: method.first, lineno: method.last)

            expect(NPlusOneQuery).to receive(:caller_locations).and_return([in_project, excluded_path])
            expect(NPlusOneQuery).to_not receive(:create_notification)
            NPlusOneQuery.call_association(@post, :association)
          end
        end
      end

      context '.caller_in_project' do
        it 'should include only paths that are in the project' do
          in_project = OpenStruct.new(absolute_path: File.join(Dir.pwd, 'abc', 'abc.rb'))
          not_in_project = OpenStruct.new(absolute_path: '/def/def.rb')

          expect(NPlusOneQuery).to receive(:caller_locations).and_return([in_project, not_in_project])
          expect(NPlusOneQuery).to receive(:conditions_met?).with(@post, :association).and_return(true)
          expect(NPlusOneQuery).to receive(:create_notification).with([in_project], 'Post', :association)
          NPlusOneQuery.call_association(@post, :association)
        end

        context 'stacktrace_includes' do
          before { Bullet.stacktrace_includes = ['def', /xyz/] }
          after { Bullet.stacktrace_includes = nil }

          it 'should include paths that are in the stacktrace_include list' do
            in_project = OpenStruct.new(absolute_path: File.join(Dir.pwd, 'abc', 'abc.rb'))
            included_gems = [OpenStruct.new(absolute_path: '/def/def.rb'), OpenStruct.new(absolute_path: 'xyz/xyz.rb')]
            excluded_gem = OpenStruct.new(absolute_path: '/ghi/ghi.rb')

            expect(NPlusOneQuery).to receive(:caller_locations).and_return([in_project, *included_gems, excluded_gem])
            expect(NPlusOneQuery).to receive(:conditions_met?).with(@post, :association).and_return(true)
            expect(NPlusOneQuery).to receive(:create_notification).with(
              [in_project, *included_gems],
              'Post',
              :association
            )
            NPlusOneQuery.call_association(@post, :association)
          end
        end
      end

      context '.add_possible_objects' do
        it 'should add possible objects' do
          NPlusOneQuery.add_possible_objects([@post, @post2])
          expect(NPlusOneQuery.possible_objects).to be_include(@post.bullet_key)
          expect(NPlusOneQuery.possible_objects).to be_include(@post2.bullet_key)
        end

        it 'should not raise error if object is nil' do
          expect { NPlusOneQuery.add_possible_objects(nil) }.not_to raise_error
        end
      end

      context '.add_impossible_object' do
        it 'should add impossible object' do
          NPlusOneQuery.add_impossible_object(@post)
          expect(NPlusOneQuery.impossible_objects).to be_include(@post.bullet_key)
        end
      end
    end
  end
end
