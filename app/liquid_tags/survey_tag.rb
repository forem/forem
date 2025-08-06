class SurveyTag < LiquidTagBase
  PARTIAL = "liquids/survey".freeze
  VALID_CONTEXTS = %w[Article].freeze # Or wherever you plan to use this

  # Using the same authorization as the PollTag for consistency
  VALID_ROLES = %i[
    admin
    super_admin
  ].freeze
  
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
      
      const totalPolls = polls.length;
      let currentPollIndex = 0; // Default to the first poll

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
      
      // --- PHASE 1: IMMEDIATE UI SETUP (for everyone) ---
      // The first poll is already visible from the server render.
      // This call sets the progress text and ensures nav buttons are correctly disabled.
      updateUI();
      
      // --- PHASE 2: ATTACH BEHAVIOR BASED ON LOGIN STATE ---
      const userIsSignedIn = document.head.querySelector('meta[name="user-signed-in"][content="true"]');

      if (userIsSignedIn) {
        // --- LOGGED-IN USER LOGIC ---
        function setAndLockAnsweredPoll(poll, votedOptionId) { /* ... as before ... */ }
        function handleVote(optionElement) { /* ... as before ... */ }

        // Re-pasting the functions here for clarity
        function setAndLockAnsweredPoll(poll, votedOptionId) {
          poll.classList.add('is-answered');
          const selectedOption = poll.querySelector(`.survey-poll-option[data-option-id="${votedOptionId}"]`);
          if (selectedOption) {
            selectedOption.classList.add('user-selected');
            poll.querySelectorAll('.survey-poll-option').forEach(opt => opt.classList.add('disabled'));
          }
        }

        function handleVote(optionElement) {
          const pollElement = optionElement.closest('.survey-poll');
          if (optionElement.classList.contains('user-selected')) return;
          const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content');
          const optionId = optionElement.dataset.optionId;
          
          window.fetch('/poll_votes', {
            method: 'POST',
            headers: { 'X-CSRF-Token': csrfToken, 'Content-Type': 'application/json' },
            body: JSON.stringify({ poll_vote: { poll_option_id: optionId } }),
            credentials: 'same-origin',
          }).then(response => {
            if (response.ok) {
              pollElement.classList.add('is-answered');
              pollElement.querySelectorAll('.survey-poll-option').forEach(opt => opt.classList.remove('user-selected'));
              optionElement.classList.add('user-selected');
              if (currentPollIndex === totalPolls - 1) {
                const finalVoteFeedbackEl = pollElement.querySelector('.survey-poll-final-vote-feedback');
                if (finalVoteFeedbackEl) finalVoteFeedbackEl.style.display = 'block';
              } else {
                const genericFeedbackEl = pollElement.querySelector('.survey-poll-feedback');
                if (genericFeedbackEl) genericFeedbackEl.style.display = 'block';
              }
              updateUI();
            } else { alert('There was a problem saving your vote. Please try again.'); }
          });
        }
        
        // Attach interactive event listeners for navigation
        if (nextBtn) { nextBtn.addEventListener('click', () => { /* ... as before ... */ }); }
        if (prevBtn) { prevBtn.addEventListener('click', () => { /* ... as before ... */ }); }
        nextBtn.addEventListener('click', () => {
          if (currentPollIndex < totalPolls - 1) {
            currentPollIndex++;
            updateUI();
          } else {
            if (pollsContainer) pollsContainer.style.display = 'none';
            if (navigation) navigation.style.display = 'none';
            if (finalMessage) finalMessage.style.display = 'block';
          }
        });
        prevBtn.addEventListener('click', () => { if (currentPollIndex > 0) { currentPollIndex--; updateUI(); } });
        
        // Fetch user's state and hydrate the UI
        window.fetch(`/surveys/${surveyId}/votes`)
          .then(response => response.ok ? response.json() : Promise.reject('Could not fetch survey votes.'))
          .then(json => {
            const userVotes = json.votes || {};
            polls.forEach(poll => {
              const votedOptionId = userVotes[poll.dataset.pollId];
              if (votedOptionId) setAndLockAnsweredPoll(poll, votedOptionId);
            });
            const correctStartingIndex = Array.from(polls).findIndex(p => !p.classList.contains('is-answered'));
            if (correctStartingIndex === -1) { 
              if (pollsContainer) pollsContainer.style.display = 'none';
              if (navigation) navigation.style.display = 'none';
              if (finalMessage) finalMessage.style.display = 'block';
              return;
            }
            if (correctStartingIndex !== currentPollIndex) {
              currentPollIndex = correctStartingIndex;
              updateUI();
            }
            polls.forEach(poll => {
              if (!poll.classList.contains('is-answered')) {
                poll.querySelectorAll('.survey-poll-option').forEach(option => {
                  option.addEventListener('click', () => handleVote(option));
                });
              }
            });
          })
          .catch(error => {
            console.error("Survey Error:", error);
            surveyElement.innerHTML = "<p>Sorry, this survey could not be loaded.</p>";
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

  def self.user_authorization_method_name
    :any_admin?
  end

  def self.script
    SCRIPT
  end

  def initialize(_tag_name, id_code, _parse_context)
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