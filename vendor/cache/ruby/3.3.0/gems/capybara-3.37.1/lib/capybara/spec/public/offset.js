$(function() {
  $(document).on('click dblclick contextmenu', function(e){
    e.preventDefault();
    $(document.body).append('<div id="has-been-clicked">Has been clicked at ' + e.clientX + ',' + e.clientY + '</div>');
  })
})