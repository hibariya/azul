module Azure
  class Config
    def initialize
      @store = {} end

    def start(&b)
      self.instance_eval &b
      self
    end

    def method_missing(name, *args)
      return @store[name] if args.empty?
      @store[name] = args.first
    end

    def attributes; @store end
  end
end
