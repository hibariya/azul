module Azul
  class Shelf
    class Work
      attr_accessor :id, :title, :person
      # 単純な通し番号をつけたい
      attr_accessor :rownum

      def initialize(args)
        args = {:title=>nil, :id=>nil, :person=>nil, :rownum=>nil}.merge(args)
        args.each{|att, val|__send__ att.to_s+'=', val}
      end
    end

  end
end
