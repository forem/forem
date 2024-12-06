var activeRequests = 0;
$(function() {
  $('#change').text('I changed it');
  $('#drag, #drag_scroll, #drag_link').draggable({
    start: function(event, ui){
      $(document.body).append(
        "<div class='drag_start'>Dragged!" +
          (event.altKey ? "-alt" : "") +
          (event.ctrlKey ? "-ctrl" : "") +
          (event.metaKey ? "-meta" : "") +
          (event.shiftKey ? "-shift" : "") +
          "</div>"
      );
    }
  });
  $('#drop, #drop_scroll').droppable({
    tolerance: 'touch',
    drop: function(event, ui) {
      ui.draggable.remove();
      $(this).html(
        "Dropped!" +
          (event.altKey ? "-alt" : "") +
          (event.ctrlKey ? "-ctrl" : "") +
          (event.metaKey ? "-meta" : "") +
          (event.shiftKey ? "-shift" : "")
      );
    }
  });
  $('#drag_html5, #drag_html5_scroll').on('dragstart', function(ev){
    $(document.body).append(
        "<div class='drag_start'>HTML5 Dragged!" +
          (event.altKey ? "-alt" : "") +
          (event.ctrlKey ? "-ctrl" : "") +
          (event.metaKey ? "-meta" : "") +
          (event.shiftKey ? "-shift" : "") +
          "</div>"
    );
    ev.originalEvent.dataTransfer.setData("text", ev.target.id);
  });
  $('#drag_html5, #drag_html5_scroll').on('dragend', function(ev){
    $(this).after('<div class="log">DragEnd with client position: ' + ev.clientX + ',' + ev.clientY)
  });
  $('#drop_html5, #drop_html5_scroll').on('dragover', function(ev){
    $(this).after('<div class="log">DragOver with client position: ' + ev.clientX + ',' + ev.clientY)
    if ($(this).hasClass('drop')) { ev.preventDefault(); }
  });
  $('#drop_html5, #drop_html5_scroll').on('dragleave', function(ev){
    $(this).after('<div class="log">DragLeave with client position: ' + ev.clientX + ',' + ev.clientY)
    if ($(this).hasClass('drop')) { ev.preventDefault(); }
  });
  $('#drop_html5, #drop_html5_scroll').on('drop', function(ev){
    $(this).after('<div class="log">Drop with client position: ' + ev.clientX + ',' + ev.clientY)
    if ($(this).hasClass('drop')) { ev.preventDefault(); }
  });
  $('#drop_html5, #drop_html5_scroll').on('drop', function(ev){
    ev.preventDefault();
    var oev = ev.originalEvent;
    if (oev.dataTransfer.items) {
      for (var i = 0; i < oev.dataTransfer.items.length; i++){
        var item = oev.dataTransfer.items[i];
        if (item.kind === 'file'){
          var file = item.getAsFile();
          $(this).append('HTML5 Dropped file: ' + file.name);
        } else {
          var _this = this;
          var callback = (function(type) {
            return function(s) {
              $(_this).append(
                "HTML5 Dropped string: " +
                  type +
                  " " +
                  s +
                  (ev.altKey ? "-alt" : "") +
                  (ev.ctrlKey ? "-ctrl" : "") +
                  (ev.metaKey ? "-meta" : "") +
                  (ev.shiftKey ? "-shift" : "")
              );
            };
          })(item.type);
          item.getAsString(callback);
        }
      }
    } else {
      $(this).html('HTML5 Dropped ' + oev.dataTransfer.getData("text"));
      for (var i = 0; i < oev.dataTransfer.files.length; i++) {
        $(this).append('HTML5 Dropped file: ' + oev.dataTransfer.files[i].name);
      }
      for (var i = 0; i < oev.dataTransfer.types.length; i++) {
        var type = oev.dataTransfer.types[i];
        $(this).append('HTML5 Dropped string: ' + type + ' ' + oev.dataTransfer.getData(type));
      }
    }
  });
  $('#clickable').click(function(e) {
    var link = $(this);
    setTimeout(function() {
      $(link).after('<a id="has-been-clicked" href="#">Has been clicked</a>');
      $(link).after('<input type="submit" value="New Here">');
      $(link).after('<input type="text" id="new_field">');
      $('#change').remove();
    }, 1000);
    return false;
  });
  $('#slow-click').click(function() {
    var link = $(this);
    setTimeout(function() {
      $(link).after('<a id="slow-clicked" href="#">Slow link clicked</a>');
    }, 4000);
    return false;
  });
  $('#aria-button').click(function() {
    var span = $(this);
    setTimeout(function() {
      $(span).after('<span role="button">ARIA button has been clicked</span>')
    }, 1000);
    return false;
  });
  $('#waiter').change(function() {
    activeRequests = 1;
    setTimeout(function() {
      activeRequests = 0;
    }, 500);
  });
  $('#with_focus_event').focus(function() {
    $('body').append('<p id="focus_event_triggered">Focus Event triggered</p>');
  });
  $('#with_change_event').change(function() {
    $('body').append($('<p class="change_event_triggered"></p>').text(this.value));
  });
  $('#with_change_event').on('input', function() {
    $('body').append($('<p class="input_event_triggered"></p>').text(this.value));
  });
  $('#checkbox_with_event').click(function() {
    $('body').append('<p id="checkbox_event_triggered">Checkbox event triggered</p>');
  });
  $('#fire_ajax_request').click(function() {
    $.ajax({url: "/slow_response", context: document.body, success: function() {
      $('body').append('<p id="ajax_request_done">Ajax request done</p>');
    }});
  });
  $('#reload-link').click(function() {
    setTimeout(function() {
      $('#reload-me').replaceWith('<div id="reload-me"><em><a>has been reloaded</a></em></div>');
    }, 250)
  });
  $('#reload-list').click(function() {
    setTimeout(function() {
      $('#the-list').html('<li>Foo</li><li>Bar</li>');
    }, 550)
  });
  $('#change-title').click(function() {
    setTimeout(function() {
      $('title').text('changed title')
    }, 400)
  });
  $('#change-size').click(function() {
    setTimeout(function() {
      document.getElementById('change').style.fontSize = '50px';
    }, 500)
  });
  $('#click-test').on({
    click: function(e) {
      window.click_delay = ((new Date().getTime()) - window.mouse_down_time)/1000.0;
      var desc = "";
      if (e.altKey) desc += 'alt ';
      if (e.ctrlKey) desc += 'control ';
      if (e.metaKey) desc += 'meta ';
      if (e.shiftKey) desc += 'shift ';
      var pos = this.getBoundingClientRect();
      $(this).after('<a id="has-been-clicked" href="#">Has been ' + desc + 'clicked at ' + (e.clientX - pos.left) + ',' + (e.clientY - pos.top) + '</a>');
    },
    dblclick: function(e) {
      var desc = "";
      if (e.altKey) desc += 'alt ';
      if (e.ctrlKey) desc += 'control ';
      if (e.metaKey) desc += 'meta ';
      if (e.shiftKey) desc += 'shift ';
      var pos = this.getBoundingClientRect();
      $(this).after('<a id="has-been-double-clicked" href="#">Has been ' + desc + 'double clicked at ' + (e.clientX - pos.left) + ',' + (e.clientY - pos.top) + '</a>');
    },
    contextmenu: function(e) {
      e.preventDefault();
      var desc = "";
      if (e.altKey) desc += 'alt ';
      if (e.ctrlKey) desc += 'control ';
      if (e.metaKey) desc += 'meta ';
      if (e.shiftKey) desc += 'shift ';
      var pos = this.getBoundingClientRect();
      $(this).after('<a id="has-been-right-clicked" href="#">Has been ' + desc + 'right clicked at ' + (e.clientX - pos.left) + ',' + (e.clientY - pos.top) + '</a>');
    },
    mousedown: function(e) {
      window.click_delay = undefined;
      window.right_click_delay = undefined;
      window.mouse_down_time = new Date().getTime();
    },
    mouseup: function(e) {
      if (e.button == 2){
        window.right_click_delay = ((new Date().getTime()) - window.mouse_down_time)/1000.0;
      }
    }
  });
  $('#open-alert').click(function() {
    alert('Alert opened [*Yay?*]');
    $(this).attr('opened', 'true');
  });
  $('#open-delayed-alert').click(function() {
    var link = this;
    setTimeout(function() {
      alert('Delayed alert opened');
      $(link).attr('opened', 'true');
    }, 250);
  });
  $('#open-slow-alert').click(function() {
    var link = this;
    setTimeout(function() {
      alert('Delayed alert opened');
      $(link).attr('opened', 'true');
    }, 3000);
  });
  $('#alert-page-change').click(function() {
    alert('Page is changing');
    return true;
  });
  $('#open-confirm').click(function() {
    if(confirm('Confirm opened')) {
      $(this).attr('confirmed', 'true');
    } else {
      $(this).attr('confirmed', 'false');
    }
  });
  $('#open-prompt').click(function() {
    var response = prompt('Prompt opened');
    if(response === null) {
      $(this).attr('response', 'dismissed');
    } else {
      $(this).attr('response', response);
    }
  });
  $('#open-prompt-with-default').click(function() {
    var response = prompt('Prompt opened', 'Default value!');
    if(response === null) {
      $(this).attr('response', 'dismissed');
    } else {
      $(this).attr('response', response);
    }
  });
  $('#open-twice').click(function() {
    if (confirm('Are you sure?')) {
      if (!confirm('Are you really sure?')) {
        $(this).attr('confirmed', 'false');
      }
    }
  });
  $('#delayed-page-change').click(function() {
    setTimeout(function() {
      window.location.pathname = '/with_html'
    }, 500)
  });
  $('#with-key-events').keydown(function(e){
    $('#key-events-output').append('keydown:'+e.which+' ')
  });
  $('#disable-on-click').click(function(e){
    var input = this;
    setTimeout(function() {
      input.disabled = true;
    }, 500)
  });
  $('#set-storage').click(function(e){
    sessionStorage.setItem('session', 'session_value');
    localStorage.setItem('local', 'local value');
  });
  $('#multiple-file, #hidden_file').change(function(e){
    $('body').append($('<p class="file_change">File input changed</p>'));
  });

  var shadow = document.querySelector('#shadow').attachShadow({mode: 'open'});
  var span = document.createElement('span');
  span.textContent = 'The things we do in the shadows';
  shadow.appendChild(span);
});
