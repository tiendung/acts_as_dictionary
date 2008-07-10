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
  
#    FIELD = "([a-zA-Z]\\w*)"
#    METHOD_REG = Regexp.new("find_by_#{FIELD}_with_spell_check|#{FIELD}_dictionary|suggest_#{FIELD}")
#
#    def method_missing(method, *args)
#      method_name = method.to_s
#      METHOD_REG =~ method_name
#      field_name = $1 || $2 || $3 || $4 || $5 || $6
#      if field_name and options[:checks].include?( field_name.to_sym )
#        case method_name
#          when /find_by/
#            # FIXME: find_by_#{field_name} instead of find_by_name
#            find_by_name denorm(dictionary(field_name).suggest(norm(args[0])).first)
#          when /dictionary/
#            dictionary(field_name)
#          when /suggest/
#            dictionary(field_name).suggest(norm(args[0])).map{ |str| denorm(str) }
#        end
#      else
#        super
#      end
#    end

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
            #{field}_dictionary.suggest( norm(str) ).map { |s| denorm(s) }
          end
        EOS
      end
    end
    
    def generate_dictionaries
      Dir.mkdir(DICT_ROOT) unless File.directory?(DICT_ROOT)
      self.options[:checks].each do |field|
        system "touch #{self.aff_file(field)}" # Don't ham file content if existed
        
        File.open(self.dic_file(field), "w+") do |file|
          items = (self.find(:all, :order => field.to_s) || [])
          items = items.map{|i| i[field]}.uniq
          file.write( items.inject("#{items.size}\n"){ |s, i| s += "#{norm(i)}\n" } )
        end
      end
      return true
    end
    
  protected
    def norm(str)
      str # str.strip.gsub(/\s+/,' ').downcase
    end
    
    def denorm(str)
      str # str.gsub(/_/, ' ')
    end
    
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
