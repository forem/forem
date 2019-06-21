class UserSimilarity
  STOP_WORDS = %w[
    a cannot into our thus about co is ours to above
    could it ourselves together across down its out too
    after during itself over toward afterwards each last own
    towards again eg latter per under against either latterly
    perhaps until all else least rather up almost elsewhere
    less same upon alone enough ltd seem us along etc
    many seemed very already even may seeming via also ever
    me seems was although every meanwhile several we always
    everyone might she well among everything more should were
    amongst everywhere moreover since what an except most so
    whatever and few mostly some when another first much
    somehow whence any for must someone whenever anyhow
    former my something where anyone formerly myself sometime
    whereafter anything from namely sometimes whereas anywhere
    further neither somewhere whereby are had never still
    wherein around has nevertheless such whereupon as have
    next than wherever at he no that whether be hence
    nobody the whither became her none their which because
    here noone them while become hereafter nor themselves who
    becomes hereby not then whoever becoming herein nothing
    thence whole been hereupon now there whom before hers
    nowhere thereafter whose beforehand herself of thereby why
    behind him off therefore will being himself often therein
    with below his on thereupon within beside how once
    these without besides however one they would between i
    only this yet beyond ie onto those you both if or
    though your but in other through yours by inc others
    throughout yourself can indeed otherwise thru yourselves'
  ].freeze

  attr_accessor :first_user, :second_user

  def initialize(first_user, second_user)
    @first_user = first_user
    @second_user = second_user
  end

  def score
    profile_score + tag_score
  end

  def profile_score
    summary_score = (first_user.summary.to_s.split(" ") & second_user.summary.to_s.split(" ") - STOP_WORDS).size
    mostly_work_with_score = (first_user.mostly_work_with.to_s.split(" ") & second_user.mostly_work_with.to_s.split(" ") - STOP_WORDS).size
    summary_score + mostly_work_with_score
  end

  def tag_score
    tag_intersection.delete("discuss")
    tag_intersection.delete("hiring")
    tag_intersection.size * 2
  end

  def tag_intersection
    first_user.cached_followed_tag_names & second_user.cached_followed_tag_names
  end
end
