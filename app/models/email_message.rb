class EmailMessage < Ahoy::Message
# So far this is mostly used to be compatable with administrate gem,
# which doesn't seem to play nicely with namespaces. But there could be other
# reasons to define behavor here, similar to how we user the Tag model.
end