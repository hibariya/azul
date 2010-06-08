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

module Azurterm
  APP_NAME = 'Azurterm'
  VERSION = File.read(File.join(File.dirname(__FILE__), '../VERSION')).strip
  CACHE_DIR = File.expand_path('~/.azurterm')
  CONF_FILE = File.join(CACHE_DIR, 'config')
  
  __here = File.dirname __FILE__
  require File.join __here, 'azurterm/config'
  require File.join __here, 'azurterm/shelf'
  require File.join __here, 'azurterm/terminal'
end


