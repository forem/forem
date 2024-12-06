var pendingQueries = []
var runningQueries = []
var maxQueries = 3

function runQuery(data, success, error) {
  if (!data.data_source) {
    throw new Error("Data source is required to cancel queries")
  }
  data.run_id = uuid()
  var query = {
    data: data,
    success: success,
    error: error,
    run_id: data.run_id,
    data_source: data.data_source,
    canceled: false
  }
  pendingQueries.push(query)
  runNext()
  return query
}

function runNext() {
  if (runningQueries.length < maxQueries) {
    var query = pendingQueries.shift()
    if (query) {
      runningQueries.push(query)
      runQueryHelper(query)
      runNext()
    }
  }
}

function runQueryHelper(query) {
  var xhr = $.ajax({
    url: Routes.run_queries_path(),
    method: "POST",
    data: query.data,
    dataType: "html"
  }).done( function (d) {
    if (d[0] == "{") {
      var response = $.parseJSON(d)
      query.data.blazer = response
      setTimeout( function () {
        if (!query.canceled) {
          runQueryHelper(query)
        }
      }, 1000)
    } else {
      if (!query.canceled) {
        query.success(d)
      }
      queryComplete(query)
    }
  }).fail( function(jqXHR, textStatus, errorThrown) {
    // check jqXHR.status instead of query.canceled
    // so it works for page navigation with Firefox and Safari
    if (jqXHR.status === 0) {
      cancelServerQuery(query)
    } else {
      var message = (typeof errorThrown === "string") ? errorThrown : errorThrown.message
      if (!message) {
        message = "An error occurred"
      }
      query.error(message)
    }
    queryComplete(query)
  })
  query.xhr = xhr
  return xhr
}

function queryComplete(query) {
  var index = runningQueries.indexOf(query)
  runningQueries.splice(index, 1)
  runNext()
}

function uuid() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8)
    return v.toString(16)
  })
}

function cancelAllQueries() {
  pendingQueries = []
  for (var i = 0; i < runningQueries.length; i++) {
    cancelQuery(runningQueries[i])
  }
}

// needed for Chrome
// queries are canceled before unload with Firefox and Safari
$(window).on("unload", cancelAllQueries)

function cancelQuery(query) {
  query.canceled = true
  if (query.xhr) {
    query.xhr.abort()
  }
}

function cancelServerQuery(query) {
  // tell server
  var path = Routes.cancel_queries_path()
  var data = {run_id: query.run_id, data_source: query.data_source}
  if (navigator.sendBeacon) {
    navigator.sendBeacon(path + "?" + $.param(csrfProtect(data)))
  } else {
    // TODO make sync
    $.post(path, data)
  }
}

function csrfProtect(payload) {
  var param = $("meta[name=csrf-param]").attr("content")
  var token = $("meta[name=csrf-token]").attr("content")
  if (param && token) payload[param] = token
  return payload
}
