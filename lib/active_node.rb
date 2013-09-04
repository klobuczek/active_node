require "active_support/dependencies/autoload"

module ActiveNode
  extend ActiveSupport::Autoload
  autoload :Base
  autoload :Callbacks
  autoload :Persistence
  autoload :Validations
  autoload :VERSION
end