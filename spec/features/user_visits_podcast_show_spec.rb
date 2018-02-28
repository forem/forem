require 'rails_helper'

feature 'User visits podcast show page' do
  let(:podcast)     { create(:podcast) }
  let(:podcast_episode)     { create(:podcast_episode, podcast_id: podcast.id) }
  let(:user)     { create(:user) }
  let(:comment)     { create(:comment,user_id:user.id,
                            commentable_id:podcast_episode.id,
                            commentable_type:"Article") }
  let(:comment2)     { create(:comment,
                              user_id:user.id,
                              commentable_id:article.id,
                              parent_id: podcast_episode.id,
                              commentable_type:"Article") }

  scenario 'they see the content of the hero' do
    visit "#{podcast_episode.path}"
    expect(page).to have_text(podcast_episode.title)
    expect(page).to have_css '.record'
  end
  scenario 'see the new comment box on the page' do
    visit "#{podcast_episode.path}"
    expect(page).to have_css 'form#new_comment'
    expect(find("#comment_commentable_type", :visible => false).value).to eq("PodcastEpisode")
    expect(find("#comment_commentable_id", :visible => false).value).to eq(podcast_episode.id.to_s)

  end
  # scenario 'see comments on the page' do
  #   visit "#{podcast_episode.path}"
  #   expect(page).to have_css '#comment-node-'+comment.id
  # end

end
