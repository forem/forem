function initializeBaseUserData(){
  var user = userData()
  var userProfileLinkHTML = '<a href="/'+user.username+'"><div class="option prime-option">@'+user.username+'</div></a>'
  document.getElementById("user-profile-link-placeholder").innerHTML = userProfileLinkHTML;
  document.getElementById("nav-profile-image").src = user.profile_image_90;
  initializeUserSidebar(user);
}

function initializeUserSidebar(user) {
  if (document.getElementById("sidebar-nav")) {
    initializeUserProfileContent(user);
    var tagHTML = "";
    var renderedTagsCount = 0;
    var followedTags = JSON.parse(user.followed_tags);
    if (followedTags.length === 0) {
        document.getElementById("tag-separator").innerHTML = "Follow tags to improve your feed"
    }
    followedTags.forEach(function(t){
      renderedTagsCount++
      tagHTML = tagHTML + '<div class="sidebar-nav-element" id="sidebar-element-'+t.name+'">\
                            <a class="sidebar-nav-link" href="/t/'+t.name+'">\
                            <span class="sidebar-nav-tag-text" style="color:'+t.text_color_hex+';background:'+t.bg_color_hex+';">#'+t.name+'</span>\
                            </a>\
                            </div>';
      if (document.getElementById("default-sidebar-element-"+t.name)){
        document.getElementById("default-sidebar-element-"+t.name).remove();
      }
    });
    document.getElementById("sidebar-nav-followed-tags").innerHTML = tagHTML;
    document.getElementById("sidebar-nav-default-tags").classList.add("showing");
  }
}

function initializeUserProfileContent(user) {
  document.getElementById("sidebar-profile-pic").innerHTML = '<img class="sidebar-profile-pic-img" src="'+user.profile_image_90+'" />'
  document.getElementById("sidebar-profile-name").innerHTML =  user.name
  document.getElementById("sidebar-profile-username").innerHTML = '@'+user.username
  document.getElementById("sidebar-profile-snapshot-inner").href = "/"+user.username;
}
