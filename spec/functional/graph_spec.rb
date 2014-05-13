require 'spec_helper'

describe ActiveNode::Graph do
  describe "#path" do
    it "should parse includes" do
      ActiveNode::Graph.new(Person, :father).send(:query).should == "optional match (n0)<-[r1:child]-(n1:`Person`)"
      ActiveNode::Graph.new(Person, :father, :children).send(:query).should == "optional match (n0)<-[r1:child]-(n1:`Person`) optional match (n0)-[r2:child]->(n2:`Person`)"
      ActiveNode::Graph.new(Person, children: 2).send(:query).should == "optional match (n0)-[r1:child*1..2]->(n1:`Person`)"
      ActiveNode::Graph.new(Person, {children: :address}, :address).send(:query).should == "optional match (n0)-[r1:child]->(n1:`Person`) optional match (n1)-[r2:address]->(n2:`Address`) optional match (n0)-[r3:address]->(n3:`Address`)"
      ActiveNode::Graph.new(Person, children: [:address, :father]).send(:query).should == "optional match (n0)-[r1:child]->(n1:`Person`) optional match (n1)-[r2:address]->(n2:`Address`) optional match (n1)<-[r3:child]-(n3:`Person`)"
      ActiveNode::Graph.new(Person, {children: 2} => [:address, :father]).send(:query).should == "optional match (n0)-[r1:child*1..2]->(n1:`Person`) optional match (n1)-[r2:address]->(n2:`Address`) optional match (n1)<-[r3:child]-(n3:`Person`)"
      ActiveNode::Graph.new(Person, {children: '*'} => [:address, :father]).send(:query).should == "optional match (n0)-[r1:child*]->(n1:`Person`) optional match (n1)-[r2:address]->(n2:`Address`) optional match (n1)<-[r3:child]-(n3:`Person`)"
    end

    it "should build graph" do
      person = Person.create! children: [c1=Person.create!, c2=Person.create!(address: a=Address.create!)]
      g_person = person.includes!({children: '*'} => [:address, :father])
      g_person = ActiveNode::Graph.new(Person, {children: '*'} => [:address, :father]).build(person).first
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
      person.includes! :children
      ActiveNode::Neo.should_not_receive(:db)
      person.children
    end
  end

  describe '#empty?' do
    it 'should return true' do
      Person.all.should be_empty
    end
  end

  describe '#detect' do
    it 'should return nil' do
      Person.all.detect { |p| true }.should be_nil
    end
  end

  describe '#includes' do
    it 'should not throw an error' do
      p = Person.create! father: Person.create!
      Person.where(id: p.id).includes(:father).first.should == p
    end
  end
end
