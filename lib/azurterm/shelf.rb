module Azurterm
  class Shelf
    __here = File.dirname __FILE__
    require File.join __here, 'shelf/raw_work.rb'
    require File.join __here, 'shelf/work.rb'
    require File.join __here, 'shelf/person.rb'

    DATABASE_FILE = File.join(CACHE_DIR, 'database')
    attr_reader :database, :works, :persons

    def initialize
      @database, @works, @persons = '', [], []
    end

    def fetch(work)
      config = Azurterm.config
      base = sprintf(config.base_uri+config.person_path, work.person.id)
      source_uri = URI.join(base, sprintf(config.card_file, work.id.to_i)).
        open{|f|f.read}.scan(/<a href=["']?([^'">]+\.zip)['">]/).flatten.first
      URI.join(base, source_uri).open do |source|
        Zip::Archive.open_buffer(source.read) do |archive|
          archive.fopen(archive.get_name(0)){|file|file.read.toutf8}
        end
      end
    end

    def grep(word)
      @database.scan /.*#{word}.*/
    end

    def search(args={})
      args = {:work=>'', :person=>'', :all=>''}.merge(args)
      mode, word = args.inject([]){|r,c|c.last.empty?? r: c}
      @persons = []
      @works = []
      __send__('search_'+mode.to_s, 
               word, grep(word).map{|r| RawWork.new r })
      @persons
    end

    def search_all(word, raw_works)
      search_person word, raw_works
      search_work word, raw_works
    end

    def search_person(word, raw_works)
      raw_works.each do |raw|
        push_raw raw if raw.person_name =~ /#{word}/
      end
    end

    def search_work(word, raw_works)
      raw_works.each do |raw|
        push_raw raw if raw.work_title =~ /#{word}/
      end
    end

    def push_raw(raw)
      person = @persons.find{|p|p.id==raw.person_id }||
        (@persons<<Person.new(:id=>raw.person_id,:name=>raw.person_name)).last
      work = @works.find{|p|p.id==raw.work_id }||
        (@works<<Work.new(:id=>raw.work_id,:title=>raw.work_title,:person=>person)).last
      work.person ||= person
      person.works<<work
      self
    end

    def load
      create_database unless File.exist?(DATABASE_FILE)
      @database = read_database
      self
    end
    def reload; create_database; self.load end

    private
    def create_database
      config = Azurterm.config
      Zip::Archive.open_buffer(URI.parse(config.base_uri+config.database_path).read) do |zip|
        zip.fopen(zip.get_name(0)) do |csv|
          data = csv.read.toutf8
          Dir.mkdir(CACHE_DIR) unless File.directory?(CACHE_DIR)
          File.open(DATABASE_FILE, 'w') do |f|
            f.write data
          end
        end
      end
    end

    def read_database
      File.open(DATABASE_FILE){|f| f.read }
    end

    __instance = self.new
    (class << self; self end).
      __send__(:define_method, :open) { __instance }

  end
end
