# -*- coding: utf-8 -*-

$KCODE = "u" unless Object.const_defined? :Encoding
STDOUT.sync = true
$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) ||
                                          $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'rubygems'
require 'mechanize'
require 'open-uri'
require 'zipruby'
require 'kconv'
require 'csv'
require 'readline'
require 'pty'
require 'expect'

module Aozora
  VERSION = File.read(File.join(File.dirname(__FILE__), '../VERSION')).strip
  APP_NAME = 'aozora'
  #CONF_DIR = File.expand_path('~/.aozora')
  #CONF_FILE = File.join(Aozora::CONF_DIR, 'config')
  #$:.unshift(CONF_DIR)

  module Reader
    class << self
    end
  end

  module Http
    @agent = Mechanize.new
    
    class << self
      def agent; @agent end

      def fetch(uri)
        page = nil
        URI.parse(uri).open do |res|
          page = res
          yield res if block_given?
        end
        page
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
        begin
          while buf = Readline.readline('> ', true)
            command.prepare(buf).call
          end
        rescue SafeExit => f
          puts f.message
          exit
        end
      end
    end
  end

  class SafeExit < RuntimeError; end

  class Command 
    def initialize
      @history = []
      @session = {}
      @current = {:width=>40}
    end

    def before
      Aozora::Shelf.load if Aozora::Shelf.persons.empty?
      update(:content=>'', :args=>[], :pipes=>[])
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
        update(:content=>self.__send__(['__', command.strip, '__'].join))
        @history<<[command, args, pipes.join('|')].join(' ')
      rescue NoMethodError => e
        update(:content=>"Command [#{command}] does not exist.")
      rescue Exception => e
        update(:content=>"Command [#{command}] failed(#{e.class}, #{e.message}).")
      ensure
        return prepared
      end
    end

    def __index__
      @session[:persons],c = {},[]
      Aozora::Shelf.persons.each_with_index{|p,i|
        @session[:persons][atoz(i)] = p
         c<<['[', atoz(i), '] ', p.name].join
      }
      c.join("\n")
    end

    def __initial__
      @session[:persons],c = {},[]
      Aozora::Shelf.persons.find_all{|p|p.initial==@current[:args].first}.each_with_index{|p,i|
        @session[:persons][atoz(i)] = p
         c<<['[', atoz(i), '] ', p.name].join
      }
      c.join("\n")
    end

    def __take__
      @session[:works],c = {},[]
      @session[:persons][@current[:args].first].works.each_with_index{|w,i| 
        @session[:works][atoz(i)] = w
        c<<['[', atoz(i), '] ', w.title].join
      }
      c.join("\n")
    end

    def __open__
      @session[:works][@current[:args].first].load.source
    end

    def __history__
      @history.join("\n")
    end

    def __exit__
      raise SafeExit, 'Finalizing...'
    end

    def __set__
      return if @current[@current[:args].first.intern].nil?
      @current[@current[:args].first.intern] = @current[:args].last
      "width => #{@current[:args].last}"
    end

    __instance = self.new
    (class << self; self end).
      __send__(:define_method, :instance) { __instance }

    COMMANDS = (self.instance_methods-(Object.instance_methods+%w[prepare prepared before update atoz set])).
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
        Aozora::Http.agent.get(sprintf(PERSON_URI, @id)).search('a').
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
        #puts page.read.toutf8.scan(/href=['"]([0-9a-zA-Z_\-\.\/]+\.zip)['"]/mi).inspect
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
        Aozora::Http.agent.get(PERSONS_URI).search('a').find_all{|tag|
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

Aozora::Display.ready

