require 'fileutils'

namespace :dict do
  desc "Install hunspell lib"
  task :install do
    hunspell = File.join(File.dirname(__FILE__), "../hunspell")
    Dir.chdir( hunspell )
    bundle_file = File.join(hunspell, "hunspell.o")
    File.delete( bundle_file ) if File.exist?( bundle_file )
    system "ruby extconf.rb && make"
  end
  
  desc "Generate dictionaries for all models"
  task :generate => :environment do
    # Borrow from ThinkingSphinx's configure.rb
    base = "#{Rails.root}/app/models/"
    Dir["#{base}**/*.rb"].each do |file|
      default_model_name = file.gsub(/^#{base}([\w_\/\\]+)\.rb/, '\1').classify      
      model_name = default_model_name.split('::').last

      klass = begin
        model_name.constantize
      rescue LoadError
        model_name.gsub!(/.*[\/\\]/, '')
        retry
      rescue NameError
        next
      end
      
      if klass.respond_to? :generate_dictionaries
        puts "Generating dictionaries for #{klass.name}..."
        klass.generate_dictionaries
      end
    end
    puts "Done."
    puts ""
  end
end