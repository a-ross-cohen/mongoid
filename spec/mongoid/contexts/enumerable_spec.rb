require "spec_helper"

describe Mongoid::Contexts::Enumerable do

  before(:all) do
    Mongoid.raise_not_found_error = true
  end

  let(:london) do
    Address.new(:number => 1, :street => "Bond Street")
  end

  let(:shanghai) do
    Address.new(:number => 10, :street => "Nan Jing Dong Lu")
  end

  let(:melbourne) do
    Address.new(:number => 20, :street => "Bourke Street")
  end

  let(:new_york) do
    Address.new(:number => 20, :street => "Broadway")
  end

  let(:berlin) do
    Address.new(:street => "Hobrechtstr")
  end

  let(:docs) do
    [ london, shanghai, melbourne, new_york, berlin ]
  end

  let(:criteria) do
    Mongoid::Criteria.new(Address).tap do |criteria|
      criteria.documents = docs
    end
  end

  let(:context) do
    Mongoid::Contexts::Enumerable.new(criteria)
  end

  describe "#aggregate" do

    let(:counts) do
      context.aggregate
    end

    before do
      context.criteria = criteria.only(:number)
    end

    it "groups by the fields provided in the options" do
      counts.size.should == 4
    end

    it "stores the counts in proper groups" do
      counts[1].should == 1
      counts[10].should == 1
      counts[20].should == 2
    end
  end

  describe "#avg" do

    it "returns the avg value for the supplied field" do
      context.avg(:number).should == 10.2
    end
  end

  describe "#count" do

    it "returns the size of the enumerable" do
      context.count.should == 5
    end
  end

  describe "#distinct" do

    context "when the criteria is limited" do

      before do
        context.criteria = criteria.where(:street => "Bourke Street")
      end

      it "returns an array of distinct values for the field" do
        context.distinct(:street).should == [ "Bourke Street" ]
      end
    end

    context "when the criteria is not limited" do

      it "returns an array of distinct values for the field" do
        context.distinct(:street).should ==
          [ "Bond Street", "Nan Jing Dong Lu", "Bourke Street", "Broadway", "Hobrechtstr" ]
      end
    end
  end

  describe "#execute" do

    it "calls sort on the filtered collection" do
      filtered_documents = []
      context.stubs(:filter).returns(filtered_documents)
      context.expects(:sort).with(filtered_documents)
      context.execute
    end

    context "when the selector is present" do

      before do
        context.criteria = criteria.where(:street => "Bourke Street")
      end

      it "returns the matching documents from the array" do
        context.execute.should == [ melbourne ]
      end
    end

    context "when selector is empty" do

      it "returns all the documents" do
        context.execute.should == docs
      end
    end

    context "when skip and limit are in the options" do

      before do
        context.criteria = criteria.skip(2).limit(2)
      end

      it "properly narrows down the matching results" do
        context.execute.should == [ melbourne, new_york ]
      end
    end

    context "when limit is set without skip in the options" do

      before do
        context.criteria = criteria.limit(2)
      end

      it "properly narrows down the matching results" do
        context.execute.size.should == 2
      end
    end

    context "when skip is set without limit in the options" do

      before do
        context.criteria = criteria.skip(2)
      end

      it "properly skips the specified records" do
        context.execute.size.should == 3
      end
    end
  end

  describe "#first" do

    context "when a selector is present" do

      before do
        context.criteria = criteria.where(:street => "Bourke Street")
      end

      it "returns the first that matches the selector" do
        context.first.should == melbourne
      end
    end
  end

  describe "#group" do

    let(:group) do
      context.group
    end

    before do
      context.criteria = criteria.only(:number)
    end

    it "groups by the fields provided in the options" do
      group.size.should == 4
    end

    it "stores the documents in proper groups" do
      group[1].should == [ london ]
      group[10].should == [ shanghai ]
      group[20].should == [ melbourne, new_york ]
    end
  end

  describe ".initialize" do

    let(:selector) { { :field => "value"  } }
    let(:options) { { :skip => 20 } }
    let(:documents) { [stub] }

    let(:crit) do
      criteria.where(selector).skip(20)
    end

    let(:context) do
      Mongoid::Contexts::Enumerable.new(crit)
    end

    before do
      crit.documents = documents
    end

    it "sets the selector" do
      context.selector.should == selector
    end

    it "sets the options" do
      context.options.should == options
    end

    it "sets the documents" do
      context.documents.should == documents
    end

  end

  describe "#iterate" do

    let(:crit) do
      criteria.where(:street => "Bourke Street")
    end

    let(:context) do
      Mongoid::Contexts::Enumerable.new(crit)
    end

    it "executes the criteria" do
      acc = []
      context.iterate do |doc|
        acc << doc
      end
      acc.should == [melbourne]
    end
  end

  describe "#limit" do

    let(:person) do
      Person.new(:title => "Sir").tap do |person|
        10.times do |n|
          post_code = n % 3 == 0 ? 32250 : 60661
          person.addresses.push(
            Address.new(
              :number => n, :post_code => post_code, :street => "Upper Street #{n}"
            )
          )
        end
      end
    end

    it "returns the specified number of documents" do
      person.addresses.criteria.limit(5).size.should == 5
    end
  end

  describe "#last" do

    context "when the selector is present" do

      let(:crit) do
        criteria.where(:street => "Bourke Street")
      end

      let(:context) do
        Mongoid::Contexts::Enumerable.new(crit)
      end

      it "returns the last matching in the enumerable" do
        context.last.should == melbourne
      end
    end
  end

  describe "#max" do

    it "returns the max value for the supplied field" do
      context.max(:number).should == 20
    end
  end

  describe "#min" do

    it "returns the min value for the supplied field" do
      context.min(:number).should == 0
    end
  end

  describe "#one" do

    context "when the selector is present" do

      let(:crit) do
        criteria.where(:street => "Bourke Street")
      end

      let(:context) do
        Mongoid::Contexts::Enumerable.new(crit)
      end

      it "returns the first matching in the enumerable" do
        context.one.should == melbourne
      end
    end
  end

  describe "#order_by" do

    let(:person) do
      Person.new(:title => "Sir").tap do |person|
        10.times do |n|
          post_code = n % 3 == 0 ? 32250 : 60661
          person.addresses.push(
            Address.new(
              :number => n, :post_code => post_code, :street => "Upper Street #{n}"
            )
          )
        end
      end
    end

    context "ascending" do

      it "sorts by a simple key" do
        person.addresses.order_by(:number.asc).
          map(&:number).should == (0..9).to_a
      end

      it "sorts by a compound key" do
        person.addresses.order_by(:post_code.asc, :number.asc).
          map(&:number).should == [0, 3, 6, 9, 1, 2, 4, 5, 7, 8]
      end
    end

    context "descending" do

      it "sorts by a simple key" do
        person.addresses.order_by(:number.desc).
          map(&:number).should == (0..9).to_a.reverse
      end

      it "sorts by a compound key" do
        person.addresses.order_by(:post_code.desc, :number.desc).
          map(&:number).should == [0, 3, 6, 9, 1, 2, 4, 5, 7, 8].reverse
      end
    end

    context "with ascending and descending" do

      it "sorts by ascending first" do
        person.addresses.order_by(:post_code.asc, :number.desc).
          map(&:number).should == [9, 6, 3, 0, 8, 7, 5, 4, 2, 1]
      end

      it "sorts by descending first" do
        person.addresses.order_by(:post_code.desc, :number.asc).
          map(&:number).should == [1, 2, 4, 5, 7, 8, 0, 3, 6, 9]
      end
    end
  end

  describe "#shift" do

    let(:person) do
      Person.new(:title => "Sir").tap do |person|
        10.times do |n|
          post_code = n % 3 == 0 ? 32250 : 60661
          person.addresses.push(
            Address.new(
              :number => n, :post_code => post_code, :street => "Upper Street #{n}"
            )
          )
        end
      end
    end

    it "returns the first element" do
      person.addresses.criteria.shift.number.should == 0
    end

    it "skips to the next value" do
      criteria = person.addresses.criteria
      criteria.shift
      criteria.shift
      criteria.first.number.should == 2
    end
  end

  describe "#skip" do

    let(:person) do
      Person.new(:title => "Sir").tap do |person|
        10.times do |n|
          post_code = n % 3 == 0 ? 32250 : 60661
          person.addresses.push(
            Address.new(
              :number => n, :post_code => post_code, :street => "Upper Street #{n}"
            )
          )
        end
      end
    end

    it "excludes the specified number of document" do
      person.addresses.criteria.skip(5).limit(10).
        map(&:number).should == [5, 6, 7, 8, 9]
    end
  end

  describe "#sort" do

    context "with no sort options" do

      it "returns the documents as is" do
        context.send(:sort, docs).should == docs
      end
    end

    context "with sort options" do

      before { context.options[:sort] = [ [:created_at, :asc] ] }

      it "sorts by the key" do
        docs.expects(:sort_by).once
        context.send(:sort, docs)
      end
    end
  end

  describe "#sum" do

    it "returns the sum of all the field values" do
      context.sum(:number).should == 51
    end
  end
end