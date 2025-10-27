class SurveyTag < LiquidTagBase
  PARTIAL = "liquids/survey".freeze
  VALID_CONTEXTS = %w[Article Billboard NilClass].freeze # Allow Article, Billboard, and nil contexts

  # Using the same authorization as the PollTag for consistency
  # But allow arbitrary usage in non-article contexts
  VALID_ROLES = %i[
    admin
    super_admin
  ].freeze

  # Override the validation to allow arbitrary usage
  def self.valid_context?(context)
    # Allow in articles (existing behavior)
    return true if context[:source].is_a?(Article)

    # Allow arbitrary usage (new behavior)
    return true if context[:source].nil?

    # Fall back to default validation
    super
  end

  # Override the authorization check to be context-aware
  def self.user_authorization_method_name
    # Return nil to skip authorization check entirely
    # We'll handle authorization in the user_authorized? method
    nil
  end

  # Override the authorization check to be context-aware
  def self.user_authorized?(user)
    # Allow if user is admin (existing behavior)
    return true if user&.any_admin?

    # Allow in arbitrary contexts (new behavior)
    true
  end

  # Override validate_contexts to allow nil sources
  def validate_contexts
    return unless self.class.const_defined? :VALID_CONTEXTS

    source = parse_context.partial_options[:source]
    # Allow nil sources for this tag
    return if source.nil?

    # For non-nil sources, use the standard validation
    raise LiquidTags::Errors::InvalidParseContext, I18n.t("liquid_tags.liquid_tag_base.no_source_found") unless source

    is_valid_source = self.class::VALID_CONTEXTS.include? source.class.name
    return if is_valid_source

    valid_contexts = self.class::VALID_CONTEXTS.map(&:pluralize).join(", ")
    invalid_source_error_msg = I18n.t("liquid_tags.liquid_tag_base.invalid_context", valid: valid_contexts)
    raise LiquidTags::Errors::InvalidParseContext, invalid_source_error_msg
  end

  SCRIPT = <<~JAVASCRIPT.freeze
    // Initialize all surveys on the page for all users
    document.querySelectorAll('.ltag-survey').forEach(initializeSurvey);

    function initializeSurvey(surveyElement) {
      // --- Get all DOM elements upfront ---
      const surveyId = surveyElement.dataset.surveyId;
      const polls = surveyElement.querySelectorAll('.survey-poll');
      const nextBtn = surveyElement.querySelector('.survey-next-btn');
      const prevBtn = surveyElement.querySelector('.survey-prev-btn');
      const progressIndicator = surveyElement.querySelector('.survey-progress');
      const finalMessage = surveyElement.querySelector('.survey-complete-message');
      const navigation = surveyElement.querySelector('.survey-navigation');
      const pollsContainer = surveyElement.querySelector('.survey-polls-container');

      if (polls.length === 0) return;
    #{'  '}
      const totalPolls = polls.length;
      let currentPollIndex = 0; // Default to the first poll
      let pendingVotes = {}; // Store pending votes for submission
      let currentSession = Math.floor(Math.random() * 1000000); // Generate random session number (0-999999)

      // --- Define UI update function (used by everyone) ---
      function updateUI() {
        // This function is safe to run for logged-out users.
        // It just displays content and sets button disabled states.
        polls.forEach((poll, index) => {
          poll.style.display = index === currentPollIndex ? 'block' : 'none';
        });
        if (progressIndicator) {
          progressIndicator.textContent = 'Question ' + (currentPollIndex + 1) + ' of ' + totalPolls;
        }
        if (prevBtn) prevBtn.disabled = currentPollIndex === 0;
        const isCurrentPollAnswered = polls[currentPollIndex]?.classList.contains('is-answered');
        if (nextBtn) {
          nextBtn.disabled = !isCurrentPollAnswered;
          if (currentPollIndex === totalPolls - 1) {
            nextBtn.textContent = 'Finish';
          } else {
            nextBtn.textContent = 'Next →';
          }
        }
      }
    #{'  '}
      // --- PHASE 1: IMMEDIATE UI SETUP (for everyone) ---
      // The first poll is already visible from the server render.
      // This call sets the progress text and ensures nav buttons are correctly disabled.
      updateUI();
    #{'  '}
      // --- PHASE 2: ATTACH BEHAVIOR BASED ON LOGIN STATE ---
      const userIsSignedIn = document.head.querySelector('meta[name="user-signed-in"][content="true"]');

      if (userIsSignedIn) {
        // --- LOGGED-IN USER LOGIC ---
        function setAndLockAnsweredPoll(poll, votedOptionIds) {
          poll.classList.add('is-answered');
          if (Array.isArray(votedOptionIds)) {
            // Multiple choice poll
            votedOptionIds.forEach(optionId => {
              const selectedOption = poll.querySelector(`.survey-poll-option[data-option-id="${optionId}"]`);
              if (selectedOption) {
                selectedOption.classList.add('user-selected');
                const checkbox = selectedOption.querySelector('input[type="checkbox"]');
                if (checkbox) checkbox.checked = true;
              }
            });
          } else if (typeof votedOptionIds === 'string' && poll.dataset.pollType === 'text_input') {
            // Text input poll with existing response
            const textarea = poll.querySelector('.survey-text-input');
            if (textarea) {
              textarea.value = votedOptionIds;
              textarea.disabled = true;
              poll.querySelector('.survey-text-input-feedback').style.display = 'block';
            }
          } else {
            // Single choice poll
            const selectedOption = poll.querySelector(`.survey-poll-option[data-option-id="${votedOptionIds}"]`);
            if (selectedOption) {
              selectedOption.classList.add('user-selected');
              const radio = selectedOption.querySelector('input[type="radio"]');
              if (radio) radio.checked = true;
            }
          }
          poll.querySelectorAll('.survey-poll-option').forEach(opt => opt.classList.add('disabled'));
        }

        function handleSelection(optionElement) {
          const pollElement = optionElement.closest('.survey-poll');
          const pollType = pollElement.dataset.pollType;
          const pollId = pollElement.dataset.pollId;
          const optionId = optionElement.dataset.optionId;
    #{'      '}
          if (pollType === 'multiple_choice') {
            // Handle multiple choice selection
            const checkbox = optionElement.querySelector('input[type="checkbox"]');
            if (checkbox) {
              checkbox.checked = !checkbox.checked;
              if (checkbox.checked) {
                optionElement.classList.add('user-selected');
              } else {
                optionElement.classList.remove('user-selected');
              }
            }
    #{'        '}
            // Store pending votes for multiple choice
            if (!pendingVotes[pollId]) {
              pendingVotes[pollId] = [];
            }
    #{'        '}
            const selectedOptions = pollElement.querySelectorAll('input[type="checkbox"]:checked');
            pendingVotes[pollId] = Array.from(selectedOptions).map(opt => opt.closest('.survey-poll-option').dataset.optionId);
    #{'        '}
            // Check if any option is selected to enable next button
            const hasSelection = selectedOptions.length > 0;
            pollElement.classList.toggle('is-answered', hasSelection);
            updateUI();
          } else {
            // Handle single choice and scale selection
            pollElement.querySelectorAll('.survey-poll-option').forEach(opt => {
              opt.classList.remove('user-selected');
              const input = opt.querySelector('input[type="radio"]');
              if (input) input.checked = false;
            });
    #{'        '}
            optionElement.classList.add('user-selected');
            const radio = optionElement.querySelector('input[type="radio"]');
            if (radio) radio.checked = true;
    #{'        '}
            // Store pending vote for single choice/scale
            pendingVotes[pollId] = optionId;
    #{'        '}
            pollElement.classList.add('is-answered');
            updateUI();
          }
        }

        function handleTextInput(pollElement) {
          const pollId = pollElement.dataset.pollId;
          const textarea = pollElement.querySelector('.survey-text-input');
          const text = textarea.value.trim();

          if (text.length > 0) {
            // Store pending text response
            pendingVotes[pollId] = { type: 'text', content: text };
            pollElement.classList.add('is-answered');
            updateUI();
          } else {
            pollElement.classList.remove('is-answered');
            updateUI();
          }
        }

        async function submitPendingVotes() {
          const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content');
          const promises = [];
    #{'      '}
          for (const [pollId, voteData] of Object.entries(pendingVotes)) {
            if (Array.isArray(voteData)) {
              // Multiple choice - submit each selected option
              voteData.forEach(optionId => {
                promises.push(
                  window.fetch('/poll_votes', {
                    method: 'POST',
                    headers: { 'X-CSRF-Token': csrfToken, 'Content-Type': 'application/json' },
                    body: JSON.stringify({ poll_vote: { poll_option_id: optionId, session_start: currentSession } }),
                    credentials: 'same-origin',
                  })
                );
              });
            } else if (typeof voteData === 'object' && voteData.type === 'text') {
              // Text input - submit text response
              promises.push(
                window.fetch(`/polls/${pollId}/poll_text_responses`, {
                  method: 'POST',
                  headers: { 'X-CSRF-Token': csrfToken, 'Content-Type': 'application/json' },
                  body: JSON.stringify({#{' '}
                    poll_text_response: {#{' '}
                      text_content: voteData.content, session_start: currentSession#{' '}
                    }#{' '}
                  }),
                  credentials: 'same-origin',
                })
              );
            } else {
              // Single choice/scale - submit single vote
              promises.push(
                window.fetch('/poll_votes', {
                  method: 'POST',
                  headers: { 'X-CSRF-Token': csrfToken, 'Content-Type': 'application/json' },
                  body: JSON.stringify({ poll_vote: { poll_option_id: voteData, session_start: currentSession } }),
                  credentials: 'same-origin',
                })
              );
            }
          }
    #{'      '}
          try {
            const responses = await Promise.all(promises);
            const failedResponses = responses.filter(response => !response.ok);
    #{'        '}
            if (failedResponses.length > 0) {
              alert('There was a problem saving some of your votes. Please try again.');
              return false;
            }
    #{'        '}
            // Clear pending votes after successful submission
            pendingVotes = {};
            return true;
          } catch (error) {
            console.error('Error submitting votes:', error);
            alert('There was a problem saving your votes. Please try again.');
            return false;
          }
        }
    #{'    '}
        // Attach interactive event listeners for navigation
        nextBtn.addEventListener('click', async () => {
          if (currentPollIndex < totalPolls - 1) {
            // Submit current poll's votes before moving to next
            const currentPoll = polls[currentPollIndex];
            const pollId = currentPoll.dataset.pollId;
    #{'        '}
            if (pendingVotes[pollId]) {
              const success = await submitPendingVotes();
              if (!success) return; // Don't proceed if submission failed
            }
    #{'        '}
            currentPollIndex++;
            updateUI();
          } else {
            // Submit final poll's votes before finishing
            const currentPoll = polls[currentPollIndex];
            const pollId = currentPoll.dataset.pollId;
    #{'        '}
            if (pendingVotes[pollId]) {
              const success = await submitPendingVotes();
              if (!success) return; // Don't proceed if submission failed
            }
    #{'        '}
            if (pollsContainer) pollsContainer.style.display = 'none';
            if (navigation) navigation.style.display = 'none';
            if (finalMessage) finalMessage.style.display = 'block';
          }
        });
    #{'    '}
        prevBtn.addEventListener('click', () => {#{' '}
          if (currentPollIndex > 0) {#{' '}
            currentPollIndex--;#{' '}
            updateUI();#{' '}
          }#{' '}
        });
    #{'    '}
        // Always attach event listeners first to ensure functionality
        polls.forEach(poll => {
          if (poll.dataset.pollType === 'text_input') {
            const textarea = poll.querySelector('.survey-text-input');
            if (textarea) {
              textarea.addEventListener('input', () => handleTextInput(poll));
            }
          } else {
            poll.querySelectorAll('.survey-poll-option').forEach(option => {
              option.addEventListener('click', () => handleSelection(option));
            });
          }
        });
    #{'    '}
        // Fetch user's state and hydrate the UI
        window.fetch(`/surveys/${surveyId}/votes`)
          .then(response => response.ok ? response.json() : Promise.reject('Could not fetch survey votes.'))
          .then(json => {
            const userVotes = json.votes || {};
            const canSubmit = json.can_submit !== false;
            const completed = json.completed === true;
            const allowResubmission = json.allow_resubmission === true;
    #{'        '}
            console.log('Survey state:', {
              completed,
              allowResubmission,
              canSubmit,
              currentSession,
              userVotes: Object.keys(userVotes).length
            });
    #{'        '}
            // For resubmission surveys, always start fresh
            if (allowResubmission) {
              console.log('Resubmission survey - starting fresh from first poll');
              // Clear all previous answers and start from first poll
              polls.forEach(poll => {
                poll.classList.remove('is-answered');
                poll.querySelectorAll('.survey-poll-option').forEach(option => {
                  option.classList.remove('user-selected');
                  option.classList.remove('disabled');
                  const input = option.querySelector('input');
                  if (input) input.checked = false;
                });
                const textarea = poll.querySelector('.survey-text-input');
                if (textarea) {
                  textarea.value = '';
                  textarea.disabled = false;
                  const feedback = poll.querySelector('.survey-text-input-feedback');
                  if (feedback) feedback.style.display = 'none';
                }
              });
              currentPollIndex = 0;
    #{'          '}
              updateUI();
              return; // Exit early - resubmission surveys always start fresh
            }
    #{'        '}
            // For non-resubmission surveys, check if completed
            if (completed) {
              console.log('Non-resubmission survey completed - showing completion message');
              if (pollsContainer) pollsContainer.style.display = 'none';
              if (navigation) navigation.style.display = 'none';
              if (finalMessage) finalMessage.style.display = 'block';
              return;
            }
    #{'        '}
            // Normal flow for non-resubmission surveys - show existing answers and jump to first unanswered
            console.log('Normal survey flow - showing existing answers and jumping to first unanswered');
            polls.forEach(poll => {
              const votedOptionIds = userVotes[poll.dataset.pollId];
              if (votedOptionIds) setAndLockAnsweredPoll(poll, votedOptionIds);
            });
            const correctStartingIndex = Array.from(polls).findIndex(p => !p.classList.contains('is-answered'));
            console.log('Correct starting index:', correctStartingIndex, 'Current poll index:', currentPollIndex);
            if (correctStartingIndex !== -1 && correctStartingIndex !== currentPollIndex) {
              console.log('Adjusting poll index from', currentPollIndex, 'to', correctStartingIndex);
              currentPollIndex = correctStartingIndex;
              updateUI();
            }

          })
          .catch(error => {
            console.error("Survey Error:", error);
            // If survey state fetch fails, still attach event listeners for fresh start
            polls.forEach(poll => {
              if (poll.dataset.pollType === 'text_input') {
                const textarea = poll.querySelector('.survey-text-input');
                if (textarea) {
                  textarea.addEventListener('input', () => handleTextInput(poll));
                }
              } else {
                poll.querySelectorAll('.survey-poll-option').forEach(option => {
                  option.addEventListener('click', () => handleSelection(option));
                });
              }
            });
          });

      } else {
        // --- LOGGED-OUT USER LOGIC ---
        // The UI is already displayed. Now, make any interaction prompt for login.
        surveyElement.addEventListener('click', (e) => {
          e.preventDefault();
          if (typeof showLoginModal !== "undefined") {
            showLoginModal();
          }
        });
      }
    }
  JAVASCRIPT

  def self.script
    SCRIPT
  end

  def initialize(_tag_name, id_code, parse_context)
    super
    # Eager load polls to avoid N+1 queries
    @survey = Survey.includes(polls: :poll_options).find(id_code)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        survey: @survey
      },
    )
  end
end

Liquid::Template.register_tag("survey", SurveyTag)
