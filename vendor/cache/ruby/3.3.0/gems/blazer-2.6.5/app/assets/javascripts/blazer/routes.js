var Routes = {
  run_queries_path: function() {
    return rootPath + "queries/run"
  },
  cancel_queries_path: function() {
    return rootPath + "queries/cancel"
  },
  schema_queries_path: function(params) {
    return rootPath + "queries/schema?" + $.param(params)
  },
  docs_queries_path: function(params) {
    return rootPath + "queries/docs?" + $.param(params)
  },
  tables_queries_path: function(params) {
    return rootPath + "queries/tables?" + $.param(params)
  },
  queries_path: function() {
    return rootPath + "queries"
  },
  query_path: function(id) {
    return rootPath + "queries/" + id
  },
  dashboard_path: function(id) {
    return rootPath + "dashboards/" + id
  }
}
