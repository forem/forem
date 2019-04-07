# adding an exit hook to properly shutdown/close third party clients
at_exit do
  Honeycomb.shutdown if defined?(Honeycomb) && Honeycomb.respond_to?(:shutdown)
end
