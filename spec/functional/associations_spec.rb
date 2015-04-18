describe ActiveNode::Associations do
  describe "#save" do
    it "should have empty association" do
      client = Client.new(name: 'a')
      client.save
      expect(client.users).to be_empty
    end

    it "should not have empty association" do
      user = NeoUser.new(name: 'Heinrich')
      user.save
      client = Client.new(name: 'a', users: [user])
      client.save
      expect(client.users).to eq([user])
    end

    it "can set association by id" do
      user = NeoUser.create!(name: 'Heinrich')
      client = Client.create!(name: 'a', user_ids: [user.id])
      expect(client.users.to_a).to eq([user])
      expect(client.user_ids).to eq([user.id])
      expect(client.users.first.clients.first).to eq(client)
      client.user_ids = []
      client.save
      expect(Client.find(client.id).users).to eq([])
      client.user_ids = [user.id]
      client.save
      expect(Client.find(client.id).users).to eq([user])
    end

    it "can remove associated objects" do
      user = NeoUser.new(name: 'Heinrich')
      user.save
      client = Client.new(name: 'a', user_ids: [user.id])
      client.save
      client.user_ids = []
      client.save
      expect(client.users).to be_empty
      expect(client.user_ids).to be_empty
    end

    it "returns nil on a has_one association for a brand spanking new model object" do
      person = Person.new
      expect(person.father).to be_nil
    end

    it "returns nil on a has_one association where nothing is associated" do
      person = Person.create!
      expect(person.father).to be_nil
    end

    it "can remove some of the associated objects" do
      child1 = Person.create!
      child2 = Person.create!
      person = Person.create! child_ids: [child1.id, child2.id]
      person = Person.find(person.id)
      expect(person.children.count).to eq(2)
      person.child_ids = [child2.id]
      person.save
      expect(Person.find(person.id).children).to eq([child2])
    end

    it "can remove and add some of the associated objects" do
      child1 = Person.create!
      child2 = Person.create!
      person = Person.create! child_ids: [child1.id, child2.id]
      person = Person.find(person.id)
      expect(person.children.count).to eq(2)
      child3 = Person.create!
      person.child_ids = [child2.id, child3.id]
      person.save
      expect(Person.find(person.id).children).to eq([child2, child3])
    end

    it 'can handle self referencing' do
      person = Person.new
      person.save
      person.people = [person]
      person.save
      person.people.first == person
      expect(Person.count).to eq(1)
    end

    it 'can handle reference to the same class' do
      id = Person.create!(children: [Person.create!, Person.create!]).id
      expect(Person.find(id).children.size).to eq(2)
    end

    it 'can set has_one relation' do
      father = Person.create!
      child = Person.create!
      child.father = father
      child.save
      expect(father.children).to eq([child])
    end

    it 'can set has_one relation by id' do
      father = Person.create!
      child = Person.create!
      child.father_id = father.id
      child.save
      expect(father.children).to eq([child])
    end

    it 'can set has_one relationship by id at creation time' do
      father = Person.create!
      child = Person.create! father_id: father.id
      expect(father.children).to eq([child])
    end

    it 'does not set has_one relationship by id if id is blank' do
      father = Person.create!
      child = Person.create! father_id: nil
      expect(father.children).to be_empty
    end

    it 'can remove has_one relationship' do
      father = Person.create!
      child = Person.create! father: father
      child.father = nil
      child.save
      expect(Person.find(child.id).father).to be_nil
    end

    it 'can read has_one relation by id' do
      father = Person.create!
      child = Person.create!
      child.father = father
      child.save
      expect(child.father_id).to eq(father.id)
    end

    it "can access new association without being saved" do
      father = Person.create!
      child = Person.new
      child.father = father
      expect(child.father).to eq(father)
    end

    it 'can handle has_one reverse relationship' do
      father = Person.create!(children: [Person.create!])
      expect(father.children.first.father).to eq(father)
    end

    it 'returns relationships to related nodes' do
      child1 = Person.create!
      child2 = Person.create!
      person = Person.create! child_ids: [child1.id, child2.id]
      person.save
      person = Person.find(person.id)
      expect(person.child_rels.map(&:other)).to eq(person.children)
    end

    it 'relationship should include property' do
      client = Client.create! name: 'Heinrich'
      client.address_rel=ActiveNode::Relationship.new(Address.create!, address_type: 'home')
      client.save
      client = Client.find(client.id)
      expect(client.address_rel[:address_type]).to eq('home')
    end

    it 'should save updated property on relationship' do
      client = Client.create! name: 'Heinrich'
      client.address_rel=ActiveNode::Relationship.new(Address.create!, address_type: 'home')
      client.save
      client = Client.find(client.id)
      client.address_rel[:address_type]='office'
      client.save
      client=Client.find(client.id)
      ar=client.address_rel
      expect(ar[:address_type]).to eq('office')
      ar[:address_type] = nil
      client.save
      expect(Client.find(client.id).address_rel[:address_type]).to be_nil
    end

    it 'should retrieve multiple relationships at once' do
      address = Address.create!
      person = Person.create! children: [Person.create!(address: address)]
      expect(Person.find(person.id).children(:address).first.address).to eq(address)
    end

    it 'should handle simultaneous updates to father and children' do
      pending
      child1 = Person.create!
      father = Person.create! children: [child1]
      father = Person.includes(:children).find(father.id)
      father.children.first.update_attributes(father: nil)
      father.update_attributes(name: "John")
      expect(Person.find(father.id).children).to be_empty?
    end

    it 'should respect object identity on retrieval with includes' do
      child1 = Person.create!
      father = Person.create! children: [child1]
      father = Person.includes(children: :father).find(father.id)
      father.update_attributes(name: "John")
      expect(father.children.first.father.name).to eq "John"
    end

    it 'should respect object identity on retrieval on demand' do
      pending
      child1 = Person.create!
      father = Person.create! children: [child1]
      father = Person.find(father.id)
      father.children.first.father.update_attributes(name: "John")
      expect(father.name).to eq "John"
    end
  end
end
