require File.dirname(__FILE__) + '/../spec_helper'

describe Azul::Shelf do
  describe "#search" do
    before do
      @shelf = Azul::Shelf.open
      @shelf.config = Azul::Config.new
    end

    it "should hit (:all=>'太宰')" do
      @shelf.search(:all=>'太宰').should_not be_empty
    end

    it "should hit (:person=>'芥川')" do
      @shelf.search(:person=>'芥川').should_not be_empty
    end
    
    it "should hit (:work=>'ヴィヨン')" do
      @shelf.search(:work=>'ヴィヨン').should_not be_empty
    end
  end

  describe "#fetch" do
    before do
      @shelf = Azul::Shelf.open
      @shelf.config = Azul::Config.new
    end

    it "should fetch an work" do
      @shelf.search(:all=>'太宰')
      str = @shelf.fetch(@shelf.persons.first.works.first)
      str.should_not be_nil
      str.should_not be_empty
    end
  end


end
