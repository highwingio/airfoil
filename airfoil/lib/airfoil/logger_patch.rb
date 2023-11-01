# The built-in Middleware gem logger truncates the event so instead
# we have our own logging middleware to print the event and context.
# Here, we reopen the class and ignoring the partial event to cut down on log chatter.
class ::Middleware::Logger
  def way_in_message name, env
    " %s has been called with: %s" % [name, env[:context].function_name]
  end

  # Default to omitting middleware logging
  def write msg
    if ENV["MIDDLEWARE_LOGGING_ENABLED"] == "true"
      @write_to.add(::Logger::INFO, msg.slice(0, 255).strip!, @middleware_name)
    end
  end
end
