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
      self.create_dict_related_methods
    end
  end

  module ClassMethods
  
    def create_dict_related_methods
      options[:checks].each do |field|
        class_eval <<-EOS, __FILE__, __LINE__
          def self.find_by_#{field}_with_spell_check(str)
            find_by_#{field} suggest_#{field}(str).first
          end
          
          def self.#{field}_dictionary
            dictionary('#{field}')
          end
        
          def self.suggest_#{field}(str)
            dictionary('#{field}').suggest(str)
          end
        EOS
      end
    end
    
    def generate_dictionaries
      Dir.mkdir(DICT_ROOT) unless File.directory?(DICT_ROOT)
      self.options[:checks].each do |field|
        system "touch #{self.aff_file(field)}" # Don't ham file content if existed
        
        File.open(self.dic_file(field), "w+") do |file|
          items = self.find(:all) || []
          items = items.inject([]){ |a, i| a += i[field].split("\n") }.uniq.sort
          file.write("#{items.size}\n#{items.join("\n")}")
        end
      end
      return true
    end
    
  protected
    def init_dictionaries
      options[:checks] = [options[:checks]].flatten.collect {|field| field.to_sym}
      options[:checks].each do |field|
        raise "'#{field}' is not valid column in #{name}." unless column_names.include? field.to_s
      end
    end
    
    def dictionary_name(field)
      "#{name.underscore}_#{field.to_s.pluralize}".to_sym
    end
    
    def dictionary(field)
       # Do lazy load
      dictionaries[dictionary_name(field)] ||= Hunspell.new(aff_file(field), dic_file(field))
    end
    
    def aff_file(field)
      File.join(DICT_ROOT, "#{dictionary_name(field)}.aff")
    end
    
    def dic_file(field)
      File.join(DICT_ROOT, "#{dictionary_name(field)}.dic")
    end
  end
  
  module InstanceMethods
  end
end 
