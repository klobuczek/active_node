ActiveNode
==========

- [![Gem Version](https://badge.fury.io/rb/active_node.png)](https://rubygems.org/gems/active_node)
- [![Build Status](https://travis-ci.org/klobuczek/active_node.png?branch=master)](https://travis-ci.org/klobuczek/active_node)
- [![Code Climate](https://codeclimate.com/github/klobuczek/active_node.png)](https://codeclimate.com/github/klobuczek/active_node)
- [![Coverage Status](https://coveralls.io/repos/klobuczek/active_node/badge.png?branch=master)](https://coveralls.io/r/klobuczek/active_node?branch=master)

This gem is not actively maintained anymore. Consider migrating to https://github.com/neo4jrb/neo4j

ActiveNode is object graph mapping layer for neo4j deployed as standalone server. It is implemented on top of [neography](http://github.com/maxdemarzi/neography) by Max De Marzi.

If you use neo4j in embedded mode with JRuby please refer to the Neo4j.rb gem at https://github.com/andreasronge/neo4j by Andreas Ronge.

## Installation

### Gemfile

Add `active_node` to your Gemfile:

```ruby
gem 'active_node'
```

In case of default neo4j installation no further configuration is required. Otherwise refer to https://github.com/maxdemarzi/neography for further configuration options.

## Usage

ActiveNode is inspired by ActiveRecord, but it implements only some of its features and if necessary provides some extensions to work with a graph database.

### Creating and Retrieving Nodes

```ruby
class Client < ActiveNode::Base
end

client = Client.create! name: 'Abc' # Creates a neo4j node with label Client and property 'name' == 'Abc'
client = Client.find client.id
client[:name] # 'Abc'
client[:name] = 'Abc Inc.'
client.save

Client.all # returns array of all clients
Client.find_by_cypher('match (c:Client) where c.name = {name}', name: 'Abc') # array of all Clients meeting given criteria
```

### Declared Attrribues

```ruby
class Client < ActiveNode::Base
  attribute :name, type: String #typed
  attribute :code #untyped
  attribute :keywords # leave array attributes untyped
  timestamps # will automatically add and maintain created_at and updated_at
end

client.name = 'Abc'
client.keywords = ['finance', 'investment']

```

### Validation
Validation is similar to ActiveModel e.g.

```ruby
validates :name, presence: true
```
 
### Association

There are 2 types of associations: has_many and has_one. With additional options they can cover all possible relationships between nodes. 

```ruby
# label, class name, relationship type are derived from the association name, direction is by default outgoing
has_one :user # node with label User connected with outgoing relationship of type 'user'
has_many :users # multiple nodes with label User connected with outgoing relationship of type 'user'
# all option customized
has_one :father, type: :child, direction: :incoming, class_name: "Person"
```

The association declarations generate readers and writers.
```ruby
Client.create!(name: 'Abc', users: [User.create!, User.create!])
Client.create!(name: 'Abc', user_id: User.create!.id)
...
client.user_ids = [user1.id, user2.id]
save
client.users # [user1, user2]
```
### Custom Label

```ruby
class Client < ActiveNode::Base
  def label
    'Company'
  end
end
```

Instances of Client will correspond to nodes with label Company.
 
## More

ActiveNode works nicely with [neography](http://github.com/maxdemarzi/neography). If at any point you need more control or want to leverage some advanced features of the neo4j REST API you can easily take advantage of the lower layer calls.

Please create a  [new issue](https://github.com/klobuczek/active_node/issues) if you are missing any important feature in active_node.

In case of any questions don't hesitate to contact me at heinrich@mail.com
