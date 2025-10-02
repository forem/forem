class PollTag < LiquidTagBase
  PARTIAL = "liquids/poll".freeze
  VALID_CONTEXTS = %w[Article].freeze

  VALID_ROLES = %i[
    admin
    super_admin
  ].freeze
  SCRIPT = <<~JAVASCRIPT.freeze
    if (document.head.querySelector('meta[name="user-signed-in"][content="true"]')) {
      function displayPollResults(json) {
        var totalVotes = json.voting_data.votes_count;
        json.voting_data.votes_distribution.forEach(function(point) {
          var pollOptionItem = document.getElementById('poll_option_list_item_'+point[0]);
          var optionText = document.getElementById('poll_option_label_'+point[0]).textContent;
          if (json.user_vote_poll_option_id === point[0]) {
            var votedClass = 'optionvotedfor'
          } else {
            var votedClass = 'optionnotvotedfor'
          }
          if (totalVotes === 0) {
            var percent = 0;
          } else {
            var percent = (point[1]/totalVotes)*100;
          }
          var roundedPercent = Math.round( percent * 10 ) / 10
          var percentFromRight = (100-roundedPercent)
          var html = '<span><span class="ltag-votepercent ltag-'+votedClass+'" style="right:'+percentFromRight+'%"></span>\
            <span class="ltag-votepercenttext">'+optionText+' — '+roundedPercent+'%</span></span>';
          pollOptionItem.innerHTML = html;
          pollOptionItem.classList.add('already-voted')
          document.getElementById('showmethemoney-'+json.poll_id).innerHTML = '<span class="ltag-voting-results-count">'+totalVotes+' total votes</span>';
        })
      }

      var polls = document.getElementsByClassName('ltag-poll');
      for (var i = 0; i < polls.length; i += 1) {
        var poll = polls[i]
        var pollId = poll.dataset.pollId
        var pollType = poll.dataset.pollType
        window.fetch('/poll_votes/'+pollId)
        .then(function(response){
          response.json().then(
            function(json) {
              if (json.voted) {
                displayPollResults(json)
              } else {
                var els = document.getElementById('poll_'+json.poll_id).getElementsByClassName('ltag-polloption');

                for (i = 0; i < els.length; i += 1) {
                  els[i].addEventListener('click', function(e) {
                    var tokenMeta = document.querySelector("meta[name='csrf-token']")
                    if (!tokenMeta) {
                      alert('Whoops. There was an error. Your vote was not counted. Try refreshing the page.')
                      return
                    }
                    var csrfToken = tokenMeta.getAttribute('content')
                    var optionId = e.target.dataset.optionId
                    
                    // Handle different poll types
                    if (pollType === 'multiple_choice') {
                      // For multiple choice, toggle the checkbox and submit all selected options
                      var checkbox = e.target.querySelector('input[type="checkbox"]')
                      if (checkbox) {
                        checkbox.checked = !checkbox.checked
                        submitMultipleChoiceVotes(json.poll_id, csrfToken)
                      }
                    } else {
                      // For single choice and scale polls, submit single vote
                      window.fetch('/poll_votes', {
                        method: 'POST',
                        headers: {
                          'X-CSRF-Token': csrfToken,
                          'Content-Type': 'application/json',
                        },
                        body: JSON.stringify({poll_vote: { poll_option_id: optionId } }),
                        credentials: 'same-origin',
                      }).then(function(response){
                        response.json().then(function(j){displayPollResults(j)})
                      })
                    }
                  });
                }

                document.getElementById('showmethemoney-'+json.poll_id).addEventListener('click', function() {
                  pollId = this.dataset.pollId
                  window.fetch('/poll_skips', {
                    method: 'POST',
                    headers: {
                      'X-CSRF-Token': csrfToken,
                      'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({poll_skip: {poll_id: pollId }}),
                    credentials: 'same-origin',
                  }).then(function(response){
                    response.json().then(function(j){displayPollResults(j)})
                  })
                });
              }
            }
          )
        })
      }

      function submitMultipleChoiceVotes(pollId, csrfToken) {
        var poll = document.getElementById('poll_'+pollId)
        var selectedOptions = poll.querySelectorAll('input[type="checkbox"]:checked')
        var optionIds = Array.from(selectedOptions).map(function(checkbox) {
          return checkbox.dataset.optionId
        })
        
        // Submit all selected options
        optionIds.forEach(function(optionId) {
          window.fetch('/poll_votes', {
            method: 'POST',
            headers: {
              'X-CSRF-Token': csrfToken,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({poll_vote: { poll_option_id: optionId } }),
            credentials: 'same-origin',
          }).then(function(response){
            response.json().then(function(j){displayPollResults(j)})
          })
        })
      }
    } else {
        var els = document.getElementsByClassName('ltag-poll')
        for (i = 0; i < els.length; i += 1) {
          els[i].onclick = function(e) {
            if (typeof showLoginModal !== "undefined") {
              showLoginModal();
            }
          }
        }
    }
  JAVASCRIPT

  # @see LiquidTagBase.user_authorization_method_name for discussion
  def self.user_authorization_method_name
    :any_admin?
  end

  def self.script
    SCRIPT
  end

  def initialize(_tag_name, id_code, _parse_context)
    super
    @poll = Poll.find(id_code)
  end

  def render(_context)
    ApplicationController.render(
      partial: PARTIAL,
      locals: {
        poll: @poll
      },
    )
  end
end

Liquid::Template.register_tag("poll", PollTag)
