begin
  require "hunspell"
rescue LoadError
  $stderr.puts "Load build-in hunspell lib"
  require File.join(File.dirname(__FILE__),  "hunspell/Hunspell.so")
rescue LoadError
  $stderr.puts "run rake dict:install to make hunspell lib"
  exit 1
end

ActiveRecord::Base.send(:include, ActsAsDictionary) 