# -*- coding: utf-8 -*-

$KCODE = "u" unless Object.const_defined? :Encoding

$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) ||
                                          $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'rubygems'
require 'mechanize'
require 'open-uri'
require 'zipruby'
require 'kconv'
require 'csv'
require 'readline'

module Aozora
  VERSION = File.read(File.join(File.dirname(__FILE__), '../VERSION')).strip
  APP_NAME = 'aozora'
  #CONF_DIR = File.expand_path('~/.aozora')
  #CONF_FILE = File.join(Aozora::CONF_DIR, 'config')
  #$:.unshift(CONF_DIR)

  module Reader
    @commands = []

    class << self
      def run
        idx = Shelf.new
        idx.load
        puts idx.works.inspect
      end

      def init
        @commands << :hoge
      end

      def test
        puts @commands.inspect
      end
    end
  end

  module Shelf
    PERSONS_URI = 'http://www.aozora.gr.jp/index_pages/person_all.html'
    PERSON_URI = 'http://www.aozora.gr.jp/index_pages/person%d.html'
    WORK_BASE_URI = 'http://mirror.aozora.gr.jp/cards/%06d'
    WORK_PAGE_URI = [WORK_BASE_URI, '/card%d.html'].join
    WORK_FILES_BASE_URI = [WORK_BASE_URI, '/files'].join

    @persons = []
    @works = []
    @agent = Mechanize.new

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
        Aozora::Shelf.agent.get(sprintf(PERSON_URI, @id)).search('a').
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
        URI.parse(sprintf(WORK_PAGE_URI, @person.id, @id)).open do |page|
          @fetch_uri = [
            sprintf(WORK_FILES_BASE_URI, @person.id),
            '/',
            File.basename(page.read.toutf8.scan(/href=['"]([0-9a-zA-Z_\-\.\/]+\.zip)['"]/mi).flatten.last)
          ].join
        end
        self
      end

      def load
        URI.parse(load_fetch_uri.fetch_uri).open do |page|
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
        agent.get(PERSONS_URI).search('a').find_all{|tag|
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

Aozora::Shelf.load
#puts Aozora::Shelf.persons.inspect.gsub(/,/, "\n")
#puts Aozora::Shelf.works.inspect.gsub(/,/, "\n")
#Aozora::Shelf.works.first.load
#Aozora::Shelf.works.map{|wo| puts "person: #{wo.person.name}"; wo.person.works.map{|w| puts "title:#{w.title}" }}
#puts Aozora::Shelf.works.first.fetch_uri
#puts Aozora::Shelf.works.first.source
puts Aozora::Shelf.persons.length
Aozora::Shelf.persons.find_all{|p|p.id==879}.each{|p|
  puts "#{p.initial_kana}, #{p.initial}, #{p.id}, #{p.name}"
  puts '----------------------------'
  p.works.each{|w|
    puts "#{w.id}, #{w.title}"
  }
  puts '----------------------------'
  puts p.works.find{|w| w.id==14}.load.source
}

