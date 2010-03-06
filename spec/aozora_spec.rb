require File.dirname(__FILE__) + '/spec_helper'

describe Aozora do
	it 'test' do
		Aozora::Reader.new.class.should == Aozora::Reader
	end
end


