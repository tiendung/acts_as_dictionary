require 'fileutils'

namespace :dict do
  desc "Generate dictionaries for all models"
  task :generate => :environment do
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