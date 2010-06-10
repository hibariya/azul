require File.dirname(__FILE__) + '/../spec_helper'

describe Azul::Config do
  before do
    @config = Azul::Config.new
  end

  it "instance should have some default values" do
    [@config.cache_dir,
      @config.database,
      @config.database_uri,
      @config.person_uri,
      @config.card_uri,
      @config.color,
      @config.editing_mode].should be_all
  end

  it "attributes should alterable" do
    emode = 'emacs'
    col = 44
    @config.start do
      color col
      editing_mode emode
    end
    @config.editing_mode.should eql emode
    @config.color.should eql col
  end

end
