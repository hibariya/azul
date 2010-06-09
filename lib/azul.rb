# -*- coding: utf-8 -*-

$KCODE = "u" unless Object.const_defined? :Encoding
$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) ||
                                          $:.include?(File.expand_path(File.dirname(__FILE__)))
STDOUT.sync = true

require 'rubygems'
require 'open-uri'
require 'zipruby'
require 'kconv'
require 'readline'
require 'pty'
require 'expect'
require 'cgi'

module Azul
  APP_NAME = 'Azul'
  VERSION = File.read(File.join(File.dirname(__FILE__), '../VERSION')).strip
  LOCAL_FILES_DIR = File.expand_path('~/.azul')

  __here = File.dirname __FILE__
  require File.join __here, 'azul', 'config'
  require File.join __here, 'azul', 'shelf'
  require File.join __here, 'azul', 'terminal'
end


