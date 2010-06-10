module Azul
  class Shelf
    class Person
      attr_accessor :id, :name, :works
      # 単純な通し番号をつけたい
      attr_accessor :rownum

      def initialize(args)
        args = {:name=>nil, :id=>nil, :works=>[], :rownum=>nil}.merge(args)
        args.each{|att, val|__send__ att.to_s+'=', val}
      end
    end

  end
end
