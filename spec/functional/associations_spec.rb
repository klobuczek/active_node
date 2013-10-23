require 'spec_helper'

describe ActiveNode::Associations do
  describe "#save" do
    it "should have empty association" do
      client = Client.new(name: 'a')
      client.save
      client.users.should be_empty
    end

    it "should not have empty association" do
      user = NeoUser.new(name: 'Heinrich')
      user.save
      client = Client.new(name: 'a', users: [user])
      client.save
      client.users.should == [user]
    end

    it "can set association by id" do
      user = NeoUser.new(name: 'Heinrich')
      user.save
      client = Client.new(name: 'a', user_ids: [user.id])
      client.save
      client.users.should == [user]
      client.user_ids.should == [user.id]
      client.users.first.clients.first.should == client
    end

    it "can remove associated objects" do
      user = NeoUser.new(name: 'Heinrich')
      user.save
      client = Client.new(name: 'a', user_ids: [user.id])
      client.save
      client.user_ids = []
      client.save
      client.users.should be_empty
      client.user_ids.should be_empty
    end

    it "returns nil on a has_one association for a brand spanking new model object" do
      person = Person.new
      person.father.should be_nil
    end

    it "returns nil on a has_one association where nothing is associated" do
      person = Person.create!
      person.father.should be_nil
    end

    it "can remove some of the associated objects" do
      child1 = Person.create!
      child2 = Person.create!
      person = Person.create! child_ids: [child1.id, child2.id]
      person = Person.find(person.id)
      person.children.count.should == 2
      person.child_ids = [child2.id]
      person.save
      Person.find(person.id).children.should == [child2]
    end

    it "can remove and add some of the associated objects" do
      child1 = Person.create!
      child2 = Person.create!
      person = Person.create! child_ids: [child1.id, child2.id]
      person = Person.find(person.id)
      person.children.count.should == 2
      child3 = Person.create!
      person.child_ids = [child2.id, child3.id]
      person.save
      Person.find(person.id).children.should == [child2, child3]
    end

    it 'can handle self referencing' do
      person = Person.new
      person.save
      person.people = [person]
      person.save
      person.people.first == person
      Person.all.count.should == 1
    end

    it 'can handle reference to the same class' do
      id = Person.create!(children: [Person.create!, Person.create!]).id
      Person.find(id).children.size.should == 2
    end

    it 'can set has_one relation' do
      father = Person.create!
      child = Person.create!
      child.father = father
      child.save
      father.children.should == [child]
    end

    it "can access new association without being saved" do
      father = Person.create!
      child = Person.new
      child.father = father
      child.father.should == father
    end

    it 'can handle has_one reverse relationship' do
      father = Person.create!(children: [Person.create!])
      father.children.first.father.should == father
    end
  end
end
