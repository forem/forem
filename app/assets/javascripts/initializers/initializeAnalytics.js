function initializeAnalytics() {
  if (getCurrentPage("dashboards-show")) {
    var els = document.querySelectorAll('[data-analytics-pageviews]');
    if (els.length === 0) { return; }
    var ids = [];
    for(var i = 0; i < els.length; i++) {
      ids.push(els[i].dataset.articleId)
    }
    // .map(function() {return this.dataset.reactableId});
    window.fetch('/analytics?article_ids='+ids.join(","), {headers: {Accept: 'application/json'}, credentials: 'same-origin'})
    .then(function(response) {
      response.json().then(function(json) {
        var total = 0;
        for (var k in json){
          total = total + Number(json[k]);
          document.getElementById("pageviews-"+k).innerHTML = numberWithCommas(json[k]) + " VIEWS";
          document.getElementById("pageviews-"+k).classList.add("loaded");
          document.getElementById("dashboard-analytics").innerHTML = "Total Views: "+ numberWithCommas(total);
        }
        document.getElementById("dashboard-analytics-header").classList.add("loaded");
      });
    }).catch(function(err) {
      console.log(err);
    });
  }
}

function numberWithCommas(x) {
    return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}
