'use strict';

// This file is specifically used for SheCoded,
// We can try to make it more general for campaigns in the future once we know more (classnames, params).

function renderArticles(articles, articleElement ) {
  const articleHTML = articles.map((article) => {
    return `<a class="she-coded-page__some-story-container-link" href="${article.url}"><div class="she-coded-page__some-story-container">
      <div class="she-coded-page__some-story-tag"><span class="she-coded-page__some-story-hashtag">#</span>shecoded</div>
      <div class="she-coded-page__some-story-header">${article.title}</div>
      <div class="she-coded-page__some-story-info">
        <div class="she-coded-page__some-story-info-author-details">
          <div class="she-coded-page__some-story-info-pic">
            <img src="${article.user.profile_image}" alt="${article.user.name}'s profile picture"/>
          </div>
          <div class="she-coded-page__some-story-info-name">${article.user.name}</div>
        </div>
        <div class="she-coded-page__some-story-info-date">&nbsp; &#183; &nbsp; ${article.readable_publish_date}</div>
      </div>
    </div></a>`
  });



  articleElement.innerHTML = articleHTML.join(" ");
}

function renderNoArticles(articleElement) {
  articleElement.innerHTML = "<div>There are no articles to show.</div>";
}

function getArticles(articleElement) {
  let xmlhttp;
  if (window.XMLHttpRequest) {
    xmlhttp = new XMLHttpRequest();
  } else {
    xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
  }

  xmlhttp.onreadystatechange = function() {
    if (xmlhttp.readyState === XMLHttpRequest.DONE) {
      let json = JSON.parse(xmlhttp.responseText);
      document.getElementById("js-she-coded-page__loading-articles").style.display = "none";
      return json.length > 0 ? renderArticles(json, articleElement) : renderNoArticles(articleElement);
    }
  };

  let url = "/api/articles";
  let params = "tag=shecoded&per_page=12";

  xmlhttp.open("GET", `${url}?${params}`, true);
  xmlhttp.send();
}

function initializeSheCodedArticles() {
  let articleElement = document.getElementById('js-she-coded-page__some-stories-sub-container');
  if(articleElement) {
    getArticles(articleElement);
  }
}
