module Azurterm
  class Config
    def initialize
      @store = {} end
    
    def self.start(&b)
      instance.instance_eval &b
      instance
    end

    def method_missing(name, *args)
      return @store[name] if args.empty?
      @store[name] = args.first
    end

    def attributes; @store end
    
    __instance = self.new
    (class << self; self end).
      __send__(:define_method, :instance) { __instance }
  end

  # set config defaults
  Config.start do
    base_uri 'http://www.aozora.gr.jp/'
    database_path 'index_pages/list_person_all.zip'
    person_path 'cards/%s/'
    card_file 'card%s.html'
    database_expire 86400
    color 34
  end
  def self.config; Config.instance end
end
