function confirmSubmit() {
    var agree = confirm("Are you sure you wish to continue?");
    if (agree)
      return true;
    else
      return false;
  }

function submitform(event) {
    event.preventDefault();
    var myWindow = window.open("", "MsgWindow", "width=600,height=600");
    function myFunction() {
    myWindow.document.getElementById("myEmbed").src;
  document.getElementById("demo").innerHTML = x;
}
    myWindow.document.write("<p>This is 'MsgWindow'. I am 600px wide and 600px tall!</p>");
    var timer = setInterval(function() {
      if (myWindow.closed) {
        clearInterval(timer);
        document.forms['new_user'].submit();
      }
    }, 1000);
  }
