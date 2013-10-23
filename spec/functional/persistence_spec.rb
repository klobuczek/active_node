require 'spec_helper'

describe ActiveNode::Persistence do
  describe "#save" do
    it "should save not conventionally named object" do
      NeoUser.new(name: 'Heinrich').save.should be_true
      NeoUser.all.map(&:name).should == ['Heinrich']
    end

    it 'should destroy node' do
      user = NeoUser.create!(name: 'abc')
      NeoUser.all.count.should == 1
      user.destroy.should be_true
      NeoUser.all.count.should == 0
    end

    it 'should not destroy node with relationships' do
      person = Person.create! children: [Person.create!, Person.create!]
      person.destroy.should be_false
      Person.all.count.should == 3
    end

    it 'should destroy! node with relationships' do
      person = Person.create! children: [Person.create!, Person.create!]
      person.destroy!.should be_true
      Person.all.count.should == 2
    end
  end

  describe "#create!" do
    it "should persist attributes" do
      Person.create!(name: 'abc').name.should == 'abc'
    end
  end

  describe "#attributes" do
    it "should include id" do
      Person.create!(name: 'abc').attributes['id'].should_not be_nil
    end
  end
end