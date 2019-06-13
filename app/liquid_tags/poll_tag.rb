class PollTag < Liquid::Block
  PARTIAL = "liquids/poll".freeze

  def render(_context)
    # content = Nokogiri::HTML.parse(super)
    # parsed_content = content.xpath("//html/body").text

    @poll = generate_poll("parsed_content")
    ActionController::Base.new.render_to_string(
      partial: PARTIAL,
      locals: {
        poll: @poll
      },
    )
  end

  def generate_poll(input_string)
    poll = Poll.first
    poll.processed_html = input_string
  end

  def self.script
    <<~JAVASCRIPT
      if (document.head.querySelector(
        'meta[name="user-signed-in"][content="true"]',
      )) {
        console.log('create poll functionality')
        // logged in
        window.fetch('/poll_votes/1')
        .then(function(response){
          response.json().then(
            function(json){
              if (json.voted) {
                var totalVotes = json.voting_data.votes_count;
                json.voting_data.votes_distribution.forEach(function(point) {
                  console.log(point[1])
                  var pollOptionItem = document.getElementById('poll_option_list_item_'+point[0]);
                  var optionText = document.getElementById('poll_option_label_'+point[0]).textContent;
                  if (json.user_vote_poll_option_id === point[0]) {
                    var votedClass = 'optionvotedfor'
                  } else {
                    var votedClass = 'optionnotvotedfor'
                  }
                  var percent = (100-(point[1]/totalVotes)*100)
                  var roundedPercent = Math.round( percent * 10 ) / 10
                  var html = '<span><span class="ltag-votepercent ltag-'+votedClass+'" style="right:'+roundedPercent+'%"></span>\
                    <span class="ltag-votepercenttext">'+optionText+' — '+roundedPercent+'%</span></span>';
                  pollOptionItem.innerHTML = html;
                  pollOptionItem.classList.add('already-voted')
                  console.log(document.getElementById('showmethemoney'))
                  document.getElementById('showmethemoney').innerHTML = '<span class="ltag-voting-results-count">'+totalVotes+' total votes</span>'
                })
              } else {
                var els = document.getElementsByClassName('ltag-polloption')
                for (i = 0; i < els.length; i += 1) {
                  els[i].addEventListener('click', function(e) {
                    var tokenMeta = document.querySelector("meta[name='csrf-token']")
                    if (!tokenMeta) {
                      alert('Whoops. There was an error. Your vote was not counted. Try refreshing the page.')
                      return
                    }
                    var csrfToken = tokenMeta.getAttribute('content')
                    var optionId = e.target.dataset.optionId
                    console.log(e.target)
                    console.log( e.target.dataset)
                    console.log(optionId)
                    window.fetch('/poll_votes', {
                      method: 'POST',
                      headers: {
                        'X-CSRF-Token': csrfToken,
                        'Content-Type': 'application/json',
                      },
                      body: JSON.stringify({poll_vote: { poll_option_id: optionId } }),
                      credentials: 'same-origin',
                    })
                   });
                }
                document.getElementById('showmethemoney').addEventListener('click', function(e) {
                  pollId = this.dataset.pollId
                  console.log("Show me the money")
                  window.fetch('/poll_skips', {
                    method: 'POST',
                    headers: {
                      'X-CSRF-Token': csrfToken,
                      'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({poll_skip: {poll_id: pollId }}),
                    credentials: 'same-origin',
                  })
                });
              }
            }
          )
        })
      } else {
        var els = document.getElementsByClassName('ltag-poll')
        for (i = 0; i < els.length; i += 1) {
          els[i].onclick = function(e) {
            if (typeof showModal !== "undefined") { 
              showModal('poll');
            }
          }
        }
    }
    JAVASCRIPT
  end
end

Liquid::Template.register_tag("poll", PollTag)
