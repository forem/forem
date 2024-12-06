// Stupid jQuery table plugin.

(function($) {
  $.fn.stupidtable = function(sortFns) {
    return this.each(function() {
      var $table = $(this);
      sortFns = sortFns || {};
      sortFns = $.extend({}, $.fn.stupidtable.default_sort_fns, sortFns);
      $table.data('sortFns', sortFns);
      $table.stupidtable_build();

      $table.on("click.stupidtable", "thead th", function() {
          $(this).stupidsort();
      });

      // Sort th immediately if data-sort-onload="yes" is specified. Limit to
      // the first one found - only one default sort column makes sense anyway.
      var $th_onload_sort = $table.find("th[data-sort-onload=yes]").eq(0);
      $th_onload_sort.stupidsort();
    });
  };

  // ------------------------------------------------------------------
  // Default settings
  // ------------------------------------------------------------------
  $.fn.stupidtable.default_settings = {
    should_redraw: function(sort_info){
      return true;
    },
    will_manually_build_table: false
  };
  $.fn.stupidtable.dir = {ASC: "asc", DESC: "desc"};
  $.fn.stupidtable.default_sort_fns = {
    "int": function(a, b) {
      return parseInt(a, 10) - parseInt(b, 10);
    },
    "float": function(a, b) {
      return parseFloat(a) - parseFloat(b);
    },
    "string": function(a, b) {
      return a.toString().localeCompare(b.toString());
    },
    "string-ins": function(a, b) {
      a = a.toString().toLocaleLowerCase();
      b = b.toString().toLocaleLowerCase();
      return a.localeCompare(b);
    }
  };

  // Allow specification of settings on a per-table basis. Call on a table
  // jquery object. Call *before* calling .stuidtable();
  $.fn.stupidtable_settings = function(settings) {
    return this.each(function() {
      var $table = $(this);
      var final_settings = $.extend({}, $.fn.stupidtable.default_settings, settings);
      $table.stupidtable.settings = final_settings;
    });
  };


  // Expects $("#mytable").stupidtable() to have already been called.
  // Call on a table header.
  $.fn.stupidsort = function(force_direction){
    var $this_th = $(this);
    var datatype = $this_th.data("sort") || null;

    // No datatype? Nothing to do.
    if (datatype === null) {
      return;
    }

    var dir = $.fn.stupidtable.dir;
    var $table = $this_th.closest("table");

    var sort_info = {
        $th: $this_th,
        $table: $table,
        datatype: datatype
    };


    // Bring in default settings if none provided
    if(!$table.stupidtable.settings){
        $table.stupidtable.settings = $.extend({}, $.fn.stupidtable.default_settings);
    }

    sort_info.compare_fn = $table.data('sortFns')[datatype];
    sort_info.th_index = calculateTHIndex(sort_info);
    sort_info.sort_dir = calculateSortDir(force_direction, sort_info);

    $this_th.data("sort-dir", sort_info.sort_dir);
    $table.trigger("beforetablesort", {column: sort_info.th_index, direction: sort_info.sort_dir, $th: $this_th});

    // More reliable method of forcing a redraw
    $table.css("display");

    // Run sorting asynchronously on a timout to force browser redraw after
    // `beforetablesort` callback. Also avoids locking up the browser too much.
    setTimeout(function() {
      if(!$table.stupidtable.settings.will_manually_build_table){
        $table.stupidtable_build();
      }
      var table_structure = sortTable(sort_info);
      var trs = getTableRowsFromTableStructure(table_structure, sort_info);

      if(!$table.stupidtable.settings.should_redraw(sort_info)){
        return;
      }
      $table.children("tbody").append(trs);

      updateElementData(sort_info);
      $table.trigger("aftertablesort", {column: sort_info.th_index, direction: sort_info.sort_dir, $th: $this_th});
      $table.css("display");

    }, 10);
    return $this_th;
  };

  // Call on a sortable td to update its value in the sort. This should be the
  // only mechanism used to update a cell's sort value. If your display value is
  // different from your sort value, use jQuery's .text() or .html() to update
  // the td contents, Assumes stupidtable has already been called for the table.
  $.fn.updateSortVal = function(new_sort_val){
  var $this_td = $(this);
    if($this_td.is('[data-sort-value]')){
      // For visual consistency with the .data cache
      $this_td.attr('data-sort-value', new_sort_val);
    }
    $this_td.data("sort-value", new_sort_val);
    return $this_td;
  };


  $.fn.stupidtable_build = function(){
    return this.each(function() {
      var $table = $(this);
      var table_structure = [];
      var trs = $table.children("tbody").children("tr");
      trs.each(function(index,tr) {

        // ====================================================================
        // Transfer to using internal table structure
        // ====================================================================
        var ele = {
            $tr: $(tr),
            columns: [],
            index: index
        };

        $(tr).children('td').each(function(idx, td){
            var sort_val = $(td).data("sort-value");

            // Store and read from the .data cache for display text only sorts
            // instead of looking through the DOM every time
            if(typeof(sort_val) === "undefined"){
              var txt = $(td).text();
              $(td).data('sort-value', txt);
              sort_val = txt;
            }
            ele.columns.push(sort_val);
        });
        table_structure.push(ele);
      });
      $table.data('stupidsort_internaltable', table_structure);
    });
  };

  // ====================================================================
  // Private functions
  // ====================================================================
  var sortTable = function(sort_info){
    var table_structure = sort_info.$table.data('stupidsort_internaltable');
    var th_index = sort_info.th_index;
    var $th = sort_info.$th;

    var multicolumn_target_str = $th.data('sort-multicolumn');
    var multicolumn_targets;
    if(multicolumn_target_str){
        multicolumn_targets = multicolumn_target_str.split(',');
    }
    else{
        multicolumn_targets = [];
    }
    var multicolumn_th_targets = $.map(multicolumn_targets, function(identifier, i){
        return get_th(sort_info.$table, identifier);
    });

    table_structure.sort(function(e1, e2){
      var multicolumns = multicolumn_th_targets.slice(0); // shallow copy
      var diff = sort_info.compare_fn(e1.columns[th_index], e2.columns[th_index]);
      while(diff === 0 && multicolumns.length){
          var multicolumn = multicolumns[0];
          var datatype = multicolumn.$e.data("sort");
          var multiCloumnSortMethod = sort_info.$table.data('sortFns')[datatype];
          diff = multiCloumnSortMethod(e1.columns[multicolumn.index], e2.columns[multicolumn.index]);
          multicolumns.shift();
      }
      // Sort by position in the table if values are the same. This enforces a
      // stable sort across all browsers. See https://bugs.chromium.org/p/v8/issues/detail?id=90
      if (diff === 0)
        return e1.index - e2.index;
      else
        return diff;

    });

    if (sort_info.sort_dir != $.fn.stupidtable.dir.ASC){
      table_structure.reverse();
    }
      return table_structure;
  };

  var get_th = function($table, identifier){
      // identifier can be a th id or a th index number;
      var $table_ths = $table.find('th');
      var index = parseInt(identifier, 10);
      var $th;
      if(!index && index !== 0){
          $th = $table_ths.siblings('#' + identifier);
          index = $table_ths.index($th);
      }
      else{
          $th = $table_ths.eq(index);
      }
      return {index: index, $e: $th};
  };

  var getTableRowsFromTableStructure = function(table_structure, sort_info){
    // Gather individual column for callbacks
    var column = $.map(table_structure, function(ele, i){
        return [[ele.columns[sort_info.th_index], ele.$tr, i]];
    });

    /* Side effect */
    sort_info.column = column;

    // Replace the content of tbody with the sorted rows. Strangely
    // enough, .append accomplishes this for us.
    return $.map(table_structure, function(ele) { return ele.$tr; });

  };

  var updateElementData = function(sort_info){
    var $table = sort_info.$table;
    var $this_th = sort_info.$th;
    var sort_dir = $this_th.data('sort-dir');
    var th_index = sort_info.th_index;


    // Reset siblings
    $table.find("th").data("sort-dir", null).removeClass("sorting-desc sorting-asc");
    $this_th.data("sort-dir", sort_dir).addClass("sorting-"+sort_dir);
  };

  var calculateSortDir = function(force_direction, sort_info){
    var sort_dir;
    var $this_th = sort_info.$th;
    var dir = $.fn.stupidtable.dir;

    if(!!force_direction){
        sort_dir = force_direction;
    }
    else{
        sort_dir = force_direction || $this_th.data("sort-default") || dir.ASC;
        if ($this_th.data("sort-dir"))
           sort_dir = $this_th.data("sort-dir") === dir.ASC ? dir.DESC : dir.ASC;
    }
    return sort_dir;
  };

  var calculateTHIndex = function(sort_info){
    var th_index = 0;
    var base_index = sort_info.$th.index();
    sort_info.$th.parents("tr").find("th").slice(0, base_index).each(function() {
      var cols = $(this).attr("colspan") || 1;
      th_index += parseInt(cols,10);
    });
    return th_index;
  };

})(jQuery);
