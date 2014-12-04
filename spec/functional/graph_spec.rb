describe ActiveNode::Graph do
  describe "#path" do
    it "should parse includes" do
      expect(ActiveNode::Graph.new(Person, :father).send(:query)).to eq("optional match (n0)<-[r1:child]-(n1:`Person`)")
      expect(ActiveNode::Graph.new(Person, :father, :children).send(:query)).to eq("optional match (n0)<-[r1:child]-(n1:`Person`) optional match (n0)-[r2:child]->(n2:`Person`)")
      expect(ActiveNode::Graph.new(Person, children: 2).send(:query)).to eq("optional match (n0)-[r1:child*1..2]->(n1:`Person`)")
      expect(ActiveNode::Graph.new(Person, {children: :address}, :address).send(:query)).to eq("optional match (n0)-[r1:child]->(n1:`Person`) optional match (n1)-[r2:address]->(n2:`Address`) optional match (n0)-[r3:address]->(n3:`Address`)")
      expect(ActiveNode::Graph.new(Person, children: [:address, :father]).send(:query)).to eq("optional match (n0)-[r1:child]->(n1:`Person`) optional match (n1)-[r2:address]->(n2:`Address`) optional match (n1)<-[r3:child]-(n3:`Person`)")
      expect(ActiveNode::Graph.new(Person, {children: 2} => [:address, :father]).send(:query)).to eq("optional match (n0)-[r1:child*1..2]->(n1:`Person`) optional match (n1)-[r2:address]->(n2:`Address`) optional match (n1)<-[r3:child]-(n3:`Person`)")
      expect(ActiveNode::Graph.new(Person, {children: '*'} => [:address, :father]).send(:query)).to eq("optional match (n0)-[r1:child*]->(n1:`Person`) optional match (n1)-[r2:address]->(n2:`Address`) optional match (n1)<-[r3:child]-(n3:`Person`)")
    end

    it "should build graph" do
      person = Person.create! children: [c1=Person.create!, c2=Person.create!(address: a=Address.create!)]
      g_person = person.includes!({children: '*'} => [:address, :father])
      g_person = ActiveNode::Graph.new(Person, {children: '*'} => [:address, :father]).build(person).first
      expect(g_person).to eq(person)
      expect(g_person.object_id).to eq(person.object_id)
      expect(ActiveNode::Neo).not_to receive(:db)
      expect(g_person.children.last.address).to eq(a)
      g_person.children.first.father = person
      expect(g_person.children).to eq([c1, c2])
    end

    it "should not query db twice" do
      pending
      person = Person.create!
      person.includes! :children
      expect(ActiveNode::Neo).not_to receive(:db)
      person.children
    end
  end

  describe '#empty?' do
    it 'should return true' do
      expect(Person.all).to be_empty
    end
  end

  describe '#detect' do
    it 'should return nil' do
      expect(Person.all.detect { |p| true }).to be_nil
    end
  end

  describe '#includes' do
    it 'should not throw an error' do
      p = Person.create! father: Person.create!
      expect(Person.where(id: p.id).includes(:father).first).to eq(p)
    end

    it "should return correct associated objects" do
      child1 = Person.create! children: [Person.create!, Person.create!]
      person = Person.create! children: [child1]
      expect(Person.includes(children: :children).find(person.id).children).to eq([child1])
      expect(Person.includes(children: 2).find(person.id).children).to eq([child1])
      expect(Person.includes(children: '*').find(person.id).children).to eq([child1])
    end
  end
end
