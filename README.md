active_node
===========

ActiveRecord style Object Graph Mapping for neo4j


gem install active_node


```ruby
require 'rubygems'
require 'active_node'
require 'neography'

Neography.configure do |config|
  config.protocol           = "http://"
  config.server             = "localhost"
  config.port               = 7474
  config.directory          = ""  # prefix this path with '/'
  config.cypher_path        = "/cypher"
  config.gremlin_path       = "/ext/GremlinPlugin/graphdb/execute_script"
  config.log_file           = "neography.log"
  config.log_enabled        = false
  config.slow_log_threshold = 0    # time in ms for query logging
  config.max_threads        = 20
  config.authentication     = nil  # 'basic' or 'digest'
  config.username           = nil
  config.password           = nil
  config.parser             = MultiJsonParser
  end
  
@neo=Neography::Rest.new

class NeoUser < ActiveNode::Base
  attribute :name, type: String
  has_many :clients
  validates :name, presence: true

  def self.label
    'User'
  end
end

class Client < ActiveNode::Base
  attribute :name, type: String

  has_many :users, direction: :incoming, class_name: 'NeoUser'
  has_one :address

  validates :name, presence: true
end

class Address < ActiveNode::Base
end

class Person < ActiveNode::Base
  attribute :name, type: String
  attribute :multi
  timestamps

  has_many :people
  has_many :children, class_name: "Person"
  #has_many :sons, class_name: "Person"
  has_one :father, type: :child, direction: :incoming, class_name: "Person"
  has_one :address

  validates :name, uniqueness: true
end


user = NeoUser.new(name: 'Heinrich')
user.save
client = Client.new(name: 'a', users: [user])
client.save
```