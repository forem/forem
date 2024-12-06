$(function () {
  $(document).on("click", ".js-toggle-trigger", function () {
    var $container = $(this).closest(".js-toggle-container");
    return $container.toggleClass("toggle-on");
  });

  $("#enable_feature__button").on("click", function (e) {
    const featureName = $("#feature_name").val();
    const promptMessage = prompt(
      `Are you sure you want to fully enable this feature for everyone? Please enter the name of the feature to confirm it: ${featureName}`
    );

    if (promptMessage !== featureName) {
      e.preventDefault();
    }
  });
  
  $("#delete_feature__button").on("click", function (e) {
    const featureName = $("#feature_name").val();
    const promptMessage = prompt(
      `Are you sure you want to remove this feature from the list of features and disable it for everyone? Please enter the name of the feature to confirm it: ${featureName}`
    );
    
    if (promptMessage !== featureName) {
      e.preventDefault();
    }
  });
});
