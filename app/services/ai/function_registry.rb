module Ai
  ##
  # Catalog of every AI function in Forem, used to pick a model per function
  # (see Ai::FunctionConfig and Settings::AiFunctions).
  #
  # `jev: true` marks functions whose job is a judgment: a yes/no call, picking one
  # option from a known set, or placing content on a scale. Those map directly onto
  # TypeSafe System One primitives (Noul, Choice, Score) and have a Jev implementation.
  #
  # Functions that write text (summaries, copy, chat replies, trend names) stay on
  # generative models: System One models return typed judgments, not prose.
  #
  # `jev_only: true` marks functions that exist only as a Jev pass and have no Gemini
  # behavior. Their "default" option means the function is off.
  #
  # `configurable: false` marks functions whose model cannot be swapped safely at runtime
  # (e.g. embeddings, where a different model would invalidate every stored vector).
  class FunctionRegistry
    Function = Struct.new(:key, :name, :description, :group, :jev, :jev_only, :configurable, keyword_init: true) do
      def jev?
        jev
      end

      def jev_only?
        jev_only
      end

      def configurable?
        configurable
      end
    end

    GROUPS = {
      moderation: "Moderation & spam",
      classification: "Classification & ranking",
      generation: "Text generation",
      fixed: "Fixed models"
    }.freeze

    FUNCTIONS = [
      # Moderation & spam
      { key: :article_spam_check, group: :moderation, jev: true,
        name: "Article spam check",
        description: "Decides whether an article from a newer account is clearly spam, when it has a link or " \
                     "the spam escalation check flags it (Ai::ArticleCheck)." },
      { key: :comment_spam_check, group: :moderation, jev: true,
        name: "Comment spam check",
        description: "Decides whether a comment is clearly spam, when it has a link or the spam escalation " \
                     "check flags it (Ai::CommentCheck)." },
      { key: :spam_escalation, group: :moderation, jev: true, jev_only: true,
        name: "Spam escalation for content without links",
        description: "Sends articles and comments without links to the spam checks above when they look like " \
                     "spam, such as Telegram or WhatsApp contacts written as text (Ai::SpamEscalationCheck). " \
                     "Off keeps link-only escalation." },
      { key: :profile_moderation, group: :moderation, jev: true,
        name: "Profile moderation label",
        description: "Flags clear and obvious spam or abuse in new profiles (Ai::ProfileModerationLabeler)." },
      { key: :content_moderation, group: :moderation, jev: true,
        name: "Article moderation label & compellingness",
        description: "Assigns an automod label and a 0-1 compellingness score to new articles " \
                     "(Ai::ContentModerationLabeler)." },
      # Classification & ranking
      { key: :article_quality_ranking, group: :classification, jev: true,
        name: "Daily best/worst article pick",
        description: "Picks the best and worst recent article per subforem for mascot nudges " \
                     "(Ai::ArticleQualityAssessor)." },
      { key: :comment_helpfulness, group: :classification, jev: true,
        name: "Warm Welcome comment helpfulness",
        description: "Decides whether a welcome-thread comment earns the Warm Welcome badge " \
                     "(Ai::CommentHelpfulnessAssessor)." },
      { key: :badge_criteria, group: :classification, jev: true,
        name: "Badge criteria check",
        description: "Decides whether an article meets an automation's badge criteria (Ai::BadgeCriteriaAssessor)." },
      { key: :concept_article_relevance, group: :classification, jev: true,
        name: "Concept/article relevance",
        description: "Checks whether an article belongs under a Concept to tune its threshold " \
                     "(Ai::ConceptArticleEvaluator)." },
      { key: :subforem_matching, group: :classification, jev: true,
        name: "Subforem reassignment match",
        description: "Picks a better subforem for an off-topic article, or none (Ai::SubforemFinder)." },
      { key: :clickbait_score, group: :classification, jev: true,
        name: "Clickbait score",
        description: "Scores how clickbait-y an article title is, 0-1 (Ai::ArticleEnhancer)." },
      { key: :article_tag_suggestion, group: :classification, jev: true,
        name: "Tag suggestion for untagged articles",
        description: "Selects 2-4 existing tags for articles published without tags (Ai::ArticleEnhancer)." },
      { key: :tag_similarity, group: :classification, jev: true,
        name: "Tag description similarity",
        description: "Decides whether two tag descriptions mean the same thing when seeding a subforem " \
                     "(Ai::ForemTags)." },
      { key: :code_block_language_detection, group: :classification, jev: true,
        name: "Code block language detection",
        description: "Picks a syntax-highlighting language for unlabeled code blocks " \
                     "(Articles::DetectCodeBlockLanguages)." },
      # Text generation
      { key: :article_summary, group: :generation, jev: false,
        name: "Article summary", description: "Writes article summaries (Ai::ArticleSummaryGenerator)." },
      { key: :context_note, group: :generation, jev: false,
        name: "Tag context note", description: "Writes tag-based context notes (Ai::ContextNoteGenerator)." },
      { key: :freeform_context_note, group: :generation, jev: false,
        name: "Freeform context note",
        description: "Writes freeform context notes (Ai::FreeformContextNoteGenerator)." },
      { key: :email_digest_summary, group: :generation, jev: false,
        name: "Email digest summary", description: "Writes the digest email intro (Ai::EmailDigestSummary)." },
      { key: :survey_email_context, group: :generation, jev: false,
        name: "Survey email context", description: "Writes survey email context (Ai::SurveyContextGenerator)." },
      { key: :community_copy, group: :generation, jev: false,
        name: "Subforem community copy",
        description: "Writes subforem descriptions and taglines (Ai::CommunityCopy)." },
      { key: :community_tag_generation, group: :generation, jev: false,
        name: "Subforem tag generation", description: "Writes starter tags for a new subforem (Ai::ForemTags)." },
      { key: :about_page_generation, group: :generation, jev: false,
        name: "Subforem about page", description: "Writes a new subforem's about page (Ai::AboutPageGenerator)." },
      { key: :trend_metadata, group: :generation, jev: false,
        name: "Trend naming", description: "Names and describes detected trends (Ai::TrendDetector)." },
      { key: :concept_description, group: :generation, jev: false,
        name: "Concept description", description: "Writes concept descriptions (Concepts::AnchorGenerator)." },
      { key: :chat_assistant, group: :generation, jev: false,
        name: "AI chat", description: "Replies in the AI chat (Ai::ChatService)." },
      { key: :editor_helper, group: :generation, jev: false,
        name: "Editor helper", description: "Replies in the editor AI helper (Ai::EditorHelperService)." },
      { key: :github_repo_recap, group: :generation, jev: false,
        name: "GitHub repo recap", description: "Writes scheduled GitHub recaps (Ai::GithubRepoRecap)." },
      # Fixed models
      { key: :embeddings, group: :fixed, jev: false, configurable: false,
        name: "Semantic embeddings",
        description: "Embeds articles, comments and concepts (Ai::Embedding). Set with GEMINI_EMBEDDING_MODEL; " \
                     "changing it requires re-embedding stored vectors." },
      { key: :image_generation, group: :fixed, jev: false, configurable: false,
        name: "Image generation",
        description: "Generates cover and profile images (Ai::ImageGenerator) with a dedicated image model." },
    ].map { |attrs| Function.new(configurable: true, jev_only: false, **attrs).freeze }.index_by(&:key).freeze

    class UnknownFunctionError < ArgumentError; end

    class << self
      def all
        FUNCTIONS.values
      end

      def configurable
        all.select(&:configurable?)
      end

      def fetch(key)
        FUNCTIONS.fetch(key.to_sym) { raise UnknownFunctionError, "Unknown AI function: #{key}" }
      end

      def key?(key)
        FUNCTIONS.key?(key.to_s.to_sym)
      end
    end
  end
end
