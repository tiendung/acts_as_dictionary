require 'Hunspell'

module ActsAsDictionary
  DICT_ROOT = File.join(RAILS_ROOT, "dict")
  
  def self.included(base)
    base.extend ActMethods
  end
  
  module ActMethods
    def acts_as_dictionary(options)
      unless included_modules.include? InstanceMethods
        class_inheritable_reader :options, :dictionaries
        extend ClassMethods
        include InstanceMethods
      end
      write_inheritable_attribute :options, options
      write_inheritable_attribute :dictionaries, {}
      self.init_dictionaries
    end
  end
  
  module ClassMethods
    def method_missing(method, *args)
      if (match = method.to_s.match /find_by_([a-zA-Z]\w*)_with_spell_check/) and self.options[:checks].include? match[1].to_sym
        self.find_by_name self.dictionary(match[1]).suggest(args[0].downcase).first
      elsif (match = method.to_s.match /([a-zA-Z]\w*)_dictionary/) and self.options[:checks].include? match[1].to_sym
        self.dictionary(match[1])
      else
        super
      end
    end
    
    def generate_dictionaries
      Dir.mkdir(DICT_ROOT) unless File.directory?(DICT_ROOT)
      self.options[:checks].each do |field|
        File.open(self.aff_file(field), "w+") do |file|
          file.write ""
        end
        File.open(self.dic_file(field), "w+") do |file|
          file.write "#{self.count}\n#{(self.find(:all, :order => field.to_s) || []).map(&field).join("\n")}"
        end
      end
      return true
    end
    
    protected
    
    def init_dictionaries
      self.options[:checks] = [self.options[:checks]].flatten.collect {|field| field.to_sym}
      self.options[:checks].each do |field|
        raise "'#{field}' is not valid column in #{self.name}." unless self.column_names.include? field.to_s
        self.dictionaries.store self.dictionary_name(field), Hunspell.new(self.aff_file(field), self.dic_file(field))
      end
    end
    
    def dictionary_name(field)
      "#{self.name.underscore}_#{field.to_s.pluralize}".to_sym
    end
    
    def dictionary(field)
      self.dictionaries[self.dictionary_name(field)]
    end
    
    def aff_file(field)
      File.join(DICT_ROOT, "#{self.dictionary_name(field)}.aff")
    end
    
    def dic_file(field)
      File.join(DICT_ROOT, "#{self.dictionary_name(field)}.dic")
    end
  end
  
  module InstanceMethods
  end
end 
