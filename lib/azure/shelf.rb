module Azure
  class Shelf
    __here = File.dirname __FILE__
    require File.join __here, 'shelf/raw_work'
    require File.join __here, 'shelf/work'
    require File.join __here, 'shelf/person'

    attr_reader :database, :works
    attr_accessor :config, :persons

    def initialize
      @database, @works, @persons, @config = '', [], [], Config.new
    end

    def fetch(work)
      source_uri = URI.parse(sprintf(config.card_uri, work.person.id, work.id.to_i)).
        open{|f|f.read}.scan(/<a href=["']?([^'">]+\.zip)['">]/).flatten.first
      URI.join(sprintf(config.person_uri, work.person.id), source_uri).open do |source|
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
        (@persons<<Person.new(:id=>raw.person_id,:name=>raw.person_name,:rownum=>@persons.length)).last
      work = @works.find{|p|p.id==raw.work_id }||
        (@works<<Work.new(:id=>raw.work_id,:title=>raw.work_title,:person=>person,:rownum=>@works.length)).last
      work.person ||= person
      person.works<<work
      self
    end

    def load
      create_database unless File.exist?(config.database)
      @database = read_database
      self
    end
    def reload; create_database; self.load end

    private
    def create_database
      Zip::Archive.open_buffer(URI.parse(config.database_uri).read) do |zip|
        zip.fopen(zip.get_name(0)) do |csv|
          data = csv.read.toutf8
          Dir.mkdir(config.cache_dir) unless File.directory?(config.cache_dir)
          File.open(config.database, 'w') do |f|
            f.write data
          end
        end
      end
    end

    def read_database
      File.open(config.database){|f| f.read }
    end

  end
end
