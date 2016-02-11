describe ActiveNode::Persistence do
  describe "#save" do
    it "should save an object" do
      a=Address.create!
      expect(Address.find(a.id)).to eq(a)
    end

    it "should not set id property" do
      a = Address.create!
      expect(ActiveNode::Neo.db.get_node_properties(a.id)['id']).to be_nil
      a.save
      expect(ActiveNode::Neo.db.get_node_properties(a.id)['id']).to be_nil
    end

    it "should save unconventionally named object" do
      expect(NeoUser.new(name: 'Heinrich').save).to be_truthy
      expect(NeoUser.all.map(&:name)).to eq(['Heinrich'])
    end

    it "should save object with non attribute properties with a name of a relationship" do
      child = Person.create!
      person = Person.create! children: [child]
      person[:children] = "Bob"
      person.save
      person = Person.find person.id
      expect(person[:children]).to eq("Bob")
      expect(person.children).to eq([child])
    end

    it 'should destroy node' do
      user = NeoUser.create!(name: 'abc')
      expect(NeoUser.count).to eq(1)
      expect(user.destroy).to be_truthy
      expect(NeoUser.count).to eq(0)
    end

    it 'should not destroy node with relationships' do
      person = Person.create! children: [Person.create!, Person.create!]
      expect(person.destroy).to be_falsey
      expect(Person.count).to eq(3)
    end

    it 'should destroy! node with relationships' do
      person = Person.create! children: [Person.create!, Person.create!]
      expect(person.destroy!).to be_truthy
      expect(Person.count).to eq(2)
    end

    it 'should record timestamp' do
      now = Time.now
      person = Person.create!
      expect(person.created_at).not_to be_nil
      person = Person.find(person.id)
      expect(person.created_at).not_to be_nil
      expect(person.updated_at).not_to be_nil
      allow(Time).to receive(:now) { now + 1.second }
      person.name = 'abc'
      person.save
      expect(person.created_at < person.updated_at).to be_truthy
    end

    it 'should not record timestamp if not specified' do
      expect(Client.create!(name: 'abc').respond_to?(:created_at)).to be_falsey
    end

  end

  describe "#destroyed?" do
    it "returns false if a record has not been destroyed" do
      person = Person.create!
      expect(person).to_not be_destroyed
    end

    it "returns true after a record has been destroyed" do
      person = Person.create!
      person.destroy

      expect(person).to be_destroyed
    end
  end

  describe "#create!" do
    it "should persist attributes" do
      expect(Person.create!(name: 'abc').name).to eq('abc')
    end

    it "should persist array properties" do
      person = Person.create!(multi: [1, 2, 3])
      expect(Person.find(person.id).multi).to eq([1, 2, 3])
    end
  end

  describe "#find" do
    it 'should find an object by id' do
      person = Person.create!
      expect(Person.find(person.id)).to eq(person)
    end

    it 'should find objects passing multiple ids' do
      person1 = Person.create!
      person2 = Person.create!
      expect(Person.find([person1.id, person2.id]).to_a).to eq([person1, person2])
    end

    it 'should find an object with id of an unknown model' do
      expect(ActiveNode::Base.find(Person.create!.id).class).to eq(Person)
    end
  end

  describe "#attributes" do
    it "should include id" do
      expect(Person.create!(name: 'abc').attributes['id']).not_to be_nil
    end
  end

  describe "#to_param" do
    it "should return a string version of the id" do
      person = Person.create!
      expect(person.to_param).to eq(person.id.to_s)
    end

    it "should return nil if the id is nil" do
      person = Person.new
      expect(person.to_param).to be_nil
    end
  end

  describe "#persisted?" do
    it "returns true if an id is assigned and the record is not destroyed" do
      person = Person.new id: 123
      expect(person).to be_persisted
    end

    it "returns false if an id is assigned and the record is destroyed" do
      person = Person.create!
      person.destroy
      expect(person).to_not be_persisted
    end

    it "returns false if an id is not assigned" do
      person = Person.new
      expect(person).to_not be_persisted
    end
  end

  describe "#incoming" do
    it "can retrieve heterogenous models" do
      a = Address.create!
      p=Person.create!(name: 'abc', address: a)
      c=Client.create!(name: 'client', address: a)
      expect(a.incoming(:address)).to include(p, c)
      #but
      expect(a.person).to eq(p)
      expect(a.client).to eq(c)
    end
  end

  describe "#update_attribute" do
    it "should update atribute without validation" do
      client = Client.create!(name: 'abc')
      client.update_attribute(:name, nil)
      expect(Client.find(client.id).name).to be_nil
    end
  end

  describe "#wrap" do
    it "should wrap nil as nil" do
      expect(Client.wrap(nil)).to be_nil
    end
  end

  describe "default" do
    it "should default new object" do
      expect(Address.new.city).to eq "New York"
    end

    it "should default created object" do
      expect(Address.create!.city).to eq "New York"
    end
  end
end
