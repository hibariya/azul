module Aozora
  class Shelf
    class Person
      attr_accessor :id, :name, :works
      def initialize(args)
        args = {:name=>nil, :id=>nil, :works=>[]}.merge(args)
        args.each{|att, val|__send__ att.to_s+'=', val}
      end
    end

  end
end
