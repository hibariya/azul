# -*- coding: utf-8 -*-

$KCODE = "u" unless Object.const_defined? :Encoding
$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) ||
                                          $:.include?(File.expand_path(File.dirname(__FILE__)))
STDOUT.sync = true

require 'rubygems'
require 'mechanize'
require 'open-uri'
require 'zipruby'
require 'kconv'
require 'csv'
require 'readline'
require 'pty'
require 'expect'
require 'cgi'

module Aozora
  VERSION = File.read(File.join(File.dirname(__FILE__), '../VERSION')).strip
  APP_NAME = 'aozora'
  #CONF_DIR = File.expand_path('~/.aozora')
  #CONF_FILE = File.join(Aozora::CONF_DIR, 'config')
  #$:.unshift(CONF_DIR)

  module Http
    CACHE_DIR = File.expand_path('~/.aozora')
    @agent = Mechanize.new
    
    class << @agent
      def cache(uri)
        ::File.exist?([CACHE_DIR, ::CGI.escape(uri)].join('/'))? 
          nil : Aozora::Http.create_cache(::CGI.escape(uri), get(uri).body)
        get(['file://', CACHE_DIR, ::CGI.escape(uri)].join('/'))
      end
    end
   
    class << self
      def agent; @agent end

      def fetch(uri)
        cache = ''
        unless File.exist?(File.join(CACHE_DIR, ::CGI.escape(uri)))
          URI.parse(uri).open do |res|
            yield res if block_given?
            create_cache(::CGI.escape(uri), res.read)
            return res.read
          end
        else
          File.open(File.join(CACHE_DIR, ::CGI.escape(uri)), 'r') do |res|
            yield res if block_given?
            return res.read
          end
        end
      end

      def create_cache(fname, page)
        Dir.mkdir(CACHE_DIR.read) unless File.exist?(CACHE_DIR)
        File.open(File.join(CACHE_DIR, fname), 'w'){|f| f.puts page }
        self
      end

      def clear_cache
        Dir.entries(CACHE_DIR).inject([]){|r,c|
          c.match(Regexp.quote(CGI.escape(Aozora::Shelf::BASE_URI)))?
            r<<c:r
        }.map{|file|
          File.unlink(File.join(CACHE_DIR, file))
          CGI.unescape(file)
        }
      end
    end
  end

  module Display

    class << self
      def ready
        Readline.vi_editing_mode
        Readline.completion_proc = proc {|word|
          Aozora::Command::COMMANDS.grep(/\A#{Regexp.quote word}/)
        }
        command = Aozora::Command.instance
        command.prepare('h').call
        while buf = Readline.readline('> ', true)
          command.prepare(buf).call
        end
      end
    end
  end

  class Command 
    def initialize
      @history = []
      @session = {}
      @current = {:width=>60, :mode=>'vi'}
    end

    def before
      Aozora::Shelf.load if Aozora::Shelf.persons.empty?
      update(:content=>'', :args=>[], :pipes=>[])
    end

    def after
      @current[:mode]=='vi'? Readline.vi_editing_mode : Readline.emacs_editing_mode
    end

    def prepared
      update(:content=>
             @current[:content].split(/\n/).map{|line|
               chunked=[];
               line.scan(/./mu).each_slice(@current[:width].to_i){|l| chunked<<l.join }
               chunked
             }.flatten.join("\n"))

      lambda{
        system(["echo \"#{@current[:content]}\" ",
               @current[:pipes].empty? ? '' : ['|', @current[:pipes].join('|')].join].join)
      }
    end
    
    def update(args={})
      @current.merge!(args)
      self
    end
    
    def atoz(num)
      num.to_s(26).scan(/./).map{|c| 'abcdefghijklmnopqrstuvwxyz'.scan(/./)[c.to_i(26)] }.join
    end

    def prepare(text)
      commands, *pipes = text.strip.split(/\|/)
      command, *args = commands.to_s.split(/\s+/)
      return lambda{} if command.nil?
      begin
        before.update({:args=>args, :pipes=>pipes})
        begin
          update(:content=>self.__send__(command)).after
          @history<<[command, args, (!pipes.empty?? '|' : ''), pipes.join('|')].join(' ')
        rescue NoMethodError => e
          update(:content=>
                 [help].unshift(line).
                   unshift("Command [#{command}] does not exist.").
                   join("\n"))
        end
      rescue Exception => e
        update(:content=>"Command [#{command}] failed(#{e.class}, #{e.message}).")
      ensure
        return prepared
      end
    end

    def method_missing(name, *args, &block)
      guess = sprintf('__%s__', name)
      return self.__send__(guess) if self.respond_to?(guess)
      super
    end

    def __index__
      @current[:pipes]<<'less' if @current[:pipes].empty?
      @session[:persons],c = {},[]
      Aozora::Shelf.persons.each_with_index{|p,i|
        @session[:persons][atoz(i)] = p
        c<<['[', atoz(i), '] ', p.name].join
      }
      c.unshift(line).unshift("All #{c.length-1} persons listed.").join("\n")
    end

    def __initial__
      raise ArgumentError, '1 argument required' if @current[:args].first.nil?
      @current[:pipes]<<'less' if @current[:pipes].empty?
      @session[:persons],c = {},[]
      Aozora::Shelf.persons.find_all{|p|p.initial==@current[:args].first}.each_with_index{|p,i|
        @session[:persons][atoz(i)] = p
         c<<['[', atoz(i), '] ', p.name].join
      }
      c.unshift(line).unshift("Initial #{@current[:args].first}: #{c.length-1} persons listed.").join("\n")
    end

    def __take__
      raise ArgumentError, '1 argument required' if @current[:args].first.nil?
      @current[:pipes]<<'less' if @current[:pipes].empty?
      @session[:works] = {}
      @session[:person] = @session[:persons][@current[:args].first]
      __list__
    end

    def __list__
      @current[:pipes]<<'less' if @current[:pipes].empty?
      c = []
      @session[:person].works.each_with_index{|w,i| 
        @session[:works][atoz(i)] = w
        c<<['[', atoz(i), '] ', w.title].join
      }
      c.unshift(line).unshift("#{@session[:person].name}: #{c.length-1} works listed.").join("\n")
    end

    def __open__
      raise ArgumentError, '1 argument required' if @current[:args].first.nil?
      @current[:pipes]<<'less' if @current[:pipes].empty?
      [@session[:works][@current[:args].first].load.source].unshift(line).
        unshift("Opening #{@session[:person].name} #{@session[:works][@current[:args].first].title}").
        join("\n")
    end

    def __history__
      @history.unshift(line).unshift("#{@history.length-1} histories.").join("\n")
    end

    def __clear__
      Aozora::Http.clear_cache.unshift(line).unshift('Cleaning caches...').join("\n")
    end

    def __exit__
      'Finalizing...'
    end

    def __set__
      raise ArgumentError, '2 argument required' unless @current[:args].length==2
      return if @current[@current[:args].first.intern].nil?
      @current[@current[:args].first.intern] = @current[:args].last
      "#{@current[:args].first} => #{@current[:args].last}"
    end

    def __help__
      [
        ['Command', 'Summary'],
        ['index, a', 'List all persons'],
        ['initial, i', 'List persons by initial'],
        ['take, t', 'Select a person and list works'],
        ['list, l', 'List works that selected person'],
        ['open, o', 'View a work'],
        ['history, hi', 'View histories'],
        ['clear, c', 'Crear all caches'],
        ['exit, q', 'Exit'],
        ['set, s', 'Set environment'],
        ['help, h', 'View this help']
      ].map{|c| sprintf('%20s  %35s', c.first, c.last) }.
        unshift('Environments: width, mode').
        unshift('Alias examples: [a], [b], [aa], [ab]...').
        unshift('Initials: a, ka, sa, ta, na, ha, ma, ya, ra, wa').
        unshift('Usage: command [[args] [[| unix command] | ...]').
        join("\n")
    end

    def line
      Array.new(@current[:width].to_i, '=').join
    end
    
    alias __a__ __index__
    alias __i__ __initial__
    alias __t__ __take__
    alias __l__ __list__
    alias __o__ __open__
    alias __hi__ __history__
    alias __c__ __clear__
    alias __q__ __exit__
    alias __s__ __set__
    alias __h__ __help__

    __instance = self.new
    (class << self; self end).
      __send__(:define_method, :instance) { __instance }

    COMMANDS = (self.instance_methods-
                (Object.instance_methods+%w[method_missing prepare prepared before update atoz line])).
                map{|m|m.scan(/[^_]+/)}.flatten
  end

  module Shelf
    #BASE_URI = 'http://www.aozora.gr.jp/'
    BASE_URI = 'http://mirror.aozora.gr.jp/'
    PERSONS_URI = [BASE_URI, 'index_pages/person_all.html'].join
    PERSON_URI = [BASE_URI, 'index_pages/person%d.html'].join
    WORK_BASE_URI = [BASE_URI, 'cards/%06d'].join
    WORK_PAGE_URI = [WORK_BASE_URI, '/card%d.html'].join
    WORK_FILES_BASE_URI = [WORK_BASE_URI, '/files'].join

    @persons = []
    @works = []

    class Person
      attr_reader :name, :id, :initial_kana, :initial
      
      KANA_TO_ALPHA = {'ア'=>'a', 'カ'=>'ka', 'サ'=>'sa', 'タ'=>'ta', 'ナ'=>'na',
                       'ハ'=>'ha', 'マ'=>'ma', 'ヤ'=>'ya', 'ラ'=>'ra', 'ワ'=>'wa'}

      def initialize(args)
        args = {:name=>nil, :id=>nil, :initial_kana=>nil}.merge(args)
        @name = args[:name]
        @id = args[:id].to_i
        @initial_kana = args[:initial_kana]
        @initial = KANA_TO_ALPHA[args[:initial_kana]]
        @works = []
      end 

      def load_works
        Aozora::Http.agent.cache(sprintf(PERSON_URI, @id)).search('a').
          find_all{|t| t.attributes['href'].to_s =~ /cards/}.each{|tag|
          @works<<Work.new(:title=>tag.text.toutf8,
                           :id=>tag.attributes['href'].to_s.scan(/card([0-9]+)/).flatten.last,
                           :person=>self)
        }
        @works<<nil if @works.empty?
        self
      end

      def works
        return @works unless @works.empty?
        load_works.works
      end
    end 

    class Work
      attr_reader :title, :id, :person, :fetch_uri, :source

      def initialize(args)
        args = {:title=>nil, :id=>nil, :person=>nil}.merge(args)
        @title = args[:title]
        @id = args[:id].to_i
        @person = args[:person]
      end 
      
      def load_fetch_uri
        Aozora::Http.fetch(sprintf(WORK_PAGE_URI, @person.id, @id)) do |page|
          @fetch_uri = [
            sprintf(WORK_FILES_BASE_URI, @person.id),
            '/',
            File.basename(page.read.toutf8.scan(/href=['"]([0-9a-zA-Z_\-\.\/]+\.zip)['"]/mi).flatten.last)
          ].join
        end
        self
      end

      def load
        Aozora::Http.fetch(load_fetch_uri.fetch_uri) do |page|
          Zip::Archive.open_buffer(page.read) do |archive|
            archive.fopen(archive.get_name(0)) do |file|
              @source = file.read.toutf8.gsub(/\r\n/, "\n")
            end
          end
        end
        self
      end
    end 

    class << self
      attr_reader :persons, :works, :agent
      
      def load
        initial_kana = ''
        Aozora::Http.agent.cache(PERSONS_URI).search('a').find_all{|tag|
          !tag.text.empty? &&
          (!tag.attributes['name'].nil? || tag.attributes['href'].to_s =~ /person[0-9]+/)
        }.each{|tag|
          unless tag.attributes['name'].nil?
            initial_kana = tag.text.to_s.toutf8 
          else
            @persons<<Person.new(:name=>tag.text.toutf8, 
                                 :initial_kana=>initial_kana, 
                                 :id=>tag.attributes['href'].to_s.scan(/person([0-9]+)/).flatten.last)
          end
        }
        self
      end
    end
  end
end


