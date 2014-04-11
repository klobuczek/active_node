ActiveNode
==========

- [![Gem Version](https://badge.fury.io/rb/active_node.png)](https://rubygems.org/gems/active_node)
- [![Build Status](https://travis-ci.org/klobuczek/active_node.png?branch=master)](https://travis-ci.org/klobuczek/active_node)
- [![Code Climate](https://codeclimate.com/github/klobuczek/active_node.png)](https://codeclimate.com/github/klobuczek/active_node)
- [![Coverage Status](https://coveralls.io/repos/klobuczek/active_node/badge.png?branch=master)](https://coveralls.io/r/klobuczek/active_node?branch=master)


ActiveNode is object graph mapping layer for neo4j. It is implemented on top of [neography](http://github.com/maxdemarzi/neography) by Max De Marzi.


## Installation

### Gemfile

Add `active_node` to your Gemfile:

```ruby
gem 'active_node'
```

In case of default neo4j installation no further configuration is required. Otherwise refer to https://github.com/maxdemarzi/neography for further configuration options.

## Usage


```ruby
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
