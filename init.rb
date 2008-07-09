require File.join(File.dirname(__FILE__),  "hunspell/Hunspell.so")

ActiveRecord::Base.send(:include, ActsAsDictionary) 