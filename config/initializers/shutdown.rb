# adding an exit hook to properly shutdown/close third party clients
at_exit do
  Honeycomb.shutdown
end
