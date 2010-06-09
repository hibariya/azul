module Azul
  class Config
    def initialize
      @store = {
        :cache_dir => LOCAL_FILES_DIR,
        :database => File.join(LOCAL_FILES_DIR, 'database'),
        :database_uri => 'http://www.aozora.gr.jp/index_pages/list_person_all.zip',
        :person_uri => 'http://www.aozora.gr.jp/cards/%s/',
        :card_uri => 'http://www.aozora.gr.jp/cards/%s/card%s.html'
      }
    end

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
