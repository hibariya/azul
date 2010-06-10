module Azul
  class Shelf
    __here = File.dirname __FILE__
    require File.join __here, 'shelf', 'raw_work'
    require File.join __here, 'shelf', 'work'
    require File.join __here, 'shelf', 'person'

    attr_reader :database, :works
    attr_accessor :config, :persons

    def initialize
      @database, @works, @persons, @config = '', [], [], Config.new
    end

    #
    # 書庫の情報を取得済みのインスタンスを作成し返す
    #
    def self.open
      self.new.load end

    #
    # 青空文庫の文字をUTF-8へ変換する
    #
    def aozora_to_utf8(str='')
      Iconv.conv('UTF-8', 'SHIFT_JIS', str) end

    #
    # Workインスタンスからzipの取得, 展開し文字列で返す
    #
    def fetch(work)
      source_uri = URI.parse(sprintf(config.card_uri, work.person.id, work.id.gsub(/^0*/, ''))).
        open{|f|f.read}.scan(/<a href=["']?([^'">]+\.zip)['">]/i).flatten.first
      URI.parse(sprintf(config.person_uri, work.person.id)+source_uri).open do |source|
        Zip::Archive.open_buffer(source.read) do |archive|
          archive.fopen(archive.get_name(0)){|f| aozora_to_utf8 f.read }
        end
      end
    end

    #
    # 書庫から文字列を検索してヒットした行を配列で返す
    #
    def grep(word)
      @database.scan /.*#{word}.*/
    end

    #
    # 作品、人物、または全ての要素から検索を行い、検索結果を保持
    # ヒットした人物一覧を返却す
    #
    def search(args={})
      args = {:work=>'', :person=>'', :all=>''}.merge(args)
      mode, word = args.inject([]){|r,c|c.last.empty?? r: c}
      @persons = []
      @works = []
      __send__('search_'+mode.to_s, word, 
               grep(word).map{|r| RawWork.new r })
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

    #
    # RawWorkを元に@personsと@worksに追加
    #
    def push_raw(raw)
      person = @persons.find{|p|p.id==raw.person_id }||
        (@persons<<Person.new(:id=>raw.person_id,:name=>raw.person_name,:rownum=>@persons.length)).last
      work = @works.find{|p|p.id==raw.work_id }||
        (@works<<Work.new(:id=>raw.work_id,:title=>raw.work_title,:person=>person,:rownum=>@works.length)).last
      work.person ||= person
      person.works<<work
      self
    end

    #
    # 書庫ファイルが無ければ作成し、書庫情報を読込む
    #
    def load
      create_database unless File.exist?(config.database)
      @database = read_database
      self
    end
    
    #
    # 明示的に書庫ファイルを作り直して書庫情報を再読込
    #
    def reload; create_database; self.load end

    private
    def create_database
      Zip::Archive.open_buffer(URI.parse(config.database_uri).read) do |zip|
        zip.fopen(zip.get_name(0)) do |csv|
          data =  aozora_to_utf8 csv.read
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
