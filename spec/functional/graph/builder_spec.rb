require 'spec_helper'

describe ActiveNode::Graph::Builder do
  describe "#path" do
    it "should parse includes" do
      ActiveNode::Graph::Builder.new(Person, :father).send(:query).should == "optional match (n0)<-[r1:child]-(n1:Person)"
      ActiveNode::Graph::Builder.new(Person, :father, :children).send(:query).should == "optional match (n0)<-[r1:child]-(n1:Person) optional match (n0)-[r2:child]->(n2:Person)"
      ActiveNode::Graph::Builder.new(Person, children: 2).send(:query).should == "optional match (n0)-[r1:child*1..2]->(n1:Person)"
      ActiveNode::Graph::Builder.new(Person, {children: :address}, :address).send(:query).should == "optional match (n0)-[r1:child]->(n1:Person) optional match (n1)-[r2:address]->(n2:Address) optional match (n0)-[r3:address]->(n3:Address)"
      ActiveNode::Graph::Builder.new(Person, children: [:address, :father]).send(:query).should == "optional match (n0)-[r1:child]->(n1:Person) optional match (n1)-[r2:address]->(n2:Address) optional match (n1)<-[r3:child]-(n3:Person)"
      ActiveNode::Graph::Builder.new(Person, {children: 2} => [:address, :father]).send(:query).should == "optional match (n0)-[r1:child*1..2]->(n1:Person) optional match (n1)-[r2:address]->(n2:Address) optional match (n1)<-[r3:child]-(n3:Person)"
      ActiveNode::Graph::Builder.new(Person, {children: '*'} => [:address, :father]).send(:query).should == "optional match (n0)-[r1:child*]->(n1:Person) optional match (n1)-[r2:address]->(n2:Address) optional match (n1)<-[r3:child]-(n3:Person)"
    end

    it "should build graph" do
      person = Person.create! children: [c1=Person.create!, c2=Person.create!(address: a=Address.create!)]
      g_person = ActiveNode::Graph::Builder.new(Person, {children: '*'} => [:address, :father]).build(person).first
      g_person.should == person
      g_person.object_id.should == person.object_id
      ActiveNode::Neo.should_not_receive(:db)
      g_person.children.last.address.should == a
      g_person.children.first.father = person
      g_person.children.should == [c1, c2]
    end

    it "should not query db twice" do
      pending
      person = Person.create!
      ActiveNode::Graph::Builder.new(Person, :children).build(person)
      ActiveNode::Neo.should_not_receive(:db)
      person.children
    end
  end
end
