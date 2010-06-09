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

module Azure
  APP_NAME = 'Azure'
  VERSION = File.read(File.join(File.dirname(__FILE__), '../VERSION')).strip
  LOCAL_FILES_DIR = File.expand_path('~/.azure')

  __here = File.dirname __FILE__
  require File.join __here, 'azure', 'config'
  require File.join __here, 'azure', 'shelf'
  require File.join __here, 'azure', 'terminal'
end


