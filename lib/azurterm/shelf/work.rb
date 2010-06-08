module Azurterm
  class Shelf
    class Work
      attr_accessor :id, :title, :person

      def initialize(args)
        args = {:title=>nil, :id=>nil, :person=>nil}.merge(args)
        args.each{|att, val|__send__ att.to_s+'=', val}
      end
    end

  end
end
