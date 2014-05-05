module ActiveNode

  # = Active Node Errors
  #
  # Generic Active Node exception class.
  class ActiveNodeError < StandardError
  end

  # Raised when Active Node cannot find record by given id or set of ids.
  class RecordNotFound < ActiveNodeError
  end

  # Raised by ActiveNode::Base.save! and ActiveRecord::Base.create! methods when record cannot be
  # saved because record is invalid.
  class RecordNotSaved < ActiveNodeError
  end
end
