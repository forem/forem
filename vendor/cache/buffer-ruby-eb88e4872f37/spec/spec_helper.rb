require 'buffer'
require 'rspec'
require 'webmock/rspec'
require 'json'

require 'coveralls'
Coveralls.wear!

def travis?
  ENV['TRAVIS_CI']
end

def fixture_path
  File.expand_path(File.join("..", "fixtures"), __FILE__)
end

def fixture(file)
  File.new(File.join(fixture_path, file))
end

def post_data
<<EOF
schedules[0][days][]=mon&schedules[0][days][]=tue&schedules[0][days][]=wed&schedules[0][times][]=12:00&schedules[0][times][]=17:00&schedules[0][times][]=18:00&
EOF
end

def modify_update_response
response =<<EOF
{
    "success" : true,
    "buffer_count" : 10,
    "buffer_percentage" : 20,
    "update" : {
        "id" : "4ecda256512f7ee521000004",
        "client_id" : "4f850cc93733aa9301000002",
        "created_at" : 1320703582,
        "day" : "Saturday 26th November",
        "due_at" : 1320742680,
        "due_time" : "11:05 am",
        "media" : {
            "link" : "http://google.com",
            "title" : "Google",
            "description" : "The google homepage"
        },
        "profile_id" : "4eb854340acb04e870000010",
        "profile_service" : "twitter",
        "status" : "buffer",
        "text" : "This is an edited update",
        "text_formatted" : "This is an edited update",
        "user_id" : "4eb9276e0acb04bb81000067",
        "via" : "api"
    }
}
EOF
end

def create_update_return_body
create_update_return_body =<<EOF
{
"success" : true,
"buffer_count" : 10,
"buffer_percentage" : 20,
"updates" : [{
"id" : "4ecda256512f7ee521000004",
"created_at" : 1320703582,
"day" : "Saturday 26th November",
"due_at" : 1320742680,
"due_time" : "11:05 am",
"media" : {
"link" : "http://google.com",
"title" : "Google",
"description" : "The google homepage"
},
"profile_id" : "4eb854340acb04e870000010",
"profile_service" : "twitter",
"status" : "buffer",
"text" : "This is an example update",
"text_formatted" : "This is an example update",
"user_id" : "4eb9276e0acb04bb81000067",
"via" : "api"
}
]
}
EOF
end
def reorder_updates_body_response
return_body =<<EOF
{
"success" : true,
"updates" : [{
"id" : "4eb854340acb04e870000010",
"created_at" : 1320703582,
"day" : "Saturday 5th November",
"due_at" : 1320742680,
"due_time" : "08:01 am",
"profile_id" : "4eb854340acb04e870000010",
"profile_service" : "twitter",
"status" : "buffer",
"text" : "3 Incredible Stories Made Possible Through Twitter j.mp/u...",
"text_formatted" : "3 Incredible Stories Made Possible Through Twit...",
"user_id" : "4eb9276e0acb04bb81000067",
"via" : "safari"
}
]
}
EOF
end

def sample_schedules2
    [{ days: %w[mon tue wed],
      times: %w[12:00 17:00 18:00]},
      {days: %w[mon tue wed],
      times: %w[12:00 17:00 18:00]},
    ]

end

def base_path
  "https://api.bufferapp.com/1"
end

def access_token_param
  "access_token=some_token"
end

def stub_with_to_return(request_type, url, fixture_name, query_hash={})
  query = access_hash.merge(query_hash)
  stub_request(request_type, url).
     with(query: query).
     to_return(fixture(fixture_name))
end

def access_hash
  { 'access_token' => 'some_token'}
end

def sample_schedules
    [{ days: %w[mon tue wed],
      times: %w[12:00 17:00 18:00]}]
  # @sample_schedules = JSON.parse <<EOF
  #   [{
  #       "days" : [
  #           "mon",
  #           "tue",
  #           "wed",
  #           "thu",
  #           "fri"
  #       ],
  #       "times" : [
  #           "12:00",
  #           "17:00",
  #           "18:00"
  #       ]
  #   },
  #   {
  #           "days" : [
  #               "mon",
  #               "tue",
  #               "wed",
  #               "thu",
  #               "fri"
  #           ],
  #           "times" : [
  #               "12:00",
  #               "17:00",
  #               "18:00"
  #           ]
  #       }]
# EOF
end

