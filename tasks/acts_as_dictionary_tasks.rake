namespace :dict do
  desc "Generate dictionaries for all models"
  task :generate => :environment do
    # Borrow file name pattern from ThinkingSphinx's configure.rb
    base = "#{Rails.root}/app/models/"
    Dir["#{base}**/*.rb"].each do |file|
      model_name = file.gsub(/^#{base}([\w_\/\\]+)\.rb/, '\1')
      if model_name and not /related|parsing/i =~ file
        klass = model_name.classify.constantize

        if klass.respond_to? :generate_dictionaries
          puts "Generating dictionaries for #{klass.name}..."
          klass.generate_dictionaries
        end
      end
    end
    puts "Done."
    puts ""
  end
end