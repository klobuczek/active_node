require "active_support/dependencies/autoload"

module ActiveNode
  extend ActiveSupport::Autoload
  autoload :Base
  autoload :Callbacks
  autoload :Core
  autoload :Persistence
  autoload :Validations
  autoload :Reflection
  autoload :Dirty
  autoload :VERSION
  autoload :Neo
  autoload :Relationship
  autoload :Graph

  autoload_under 'graph' do
    autoload :QueryMethods
    autoload :FinderMethods
  end

  eager_autoload do
    autoload :ActiveNodeError, 'active_node/errors'
    autoload :Associations
  end
end