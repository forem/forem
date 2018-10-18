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
          var numString = parseInt(json[k]) < 100 ? "< 100 " : numberWithCommas(json[k]) ;
          var totalString = parseInt(total) < 100 ? "< 100 " : numberWithCommas(total) ;
          document.getElementById("pageviews-"+k).innerHTML = numString + " Views";
          document.getElementById("pageviews-"+k).classList.add("loaded");
          document.getElementById("dashboard-analytics").innerHTML = totalString+ " Total Views";
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
