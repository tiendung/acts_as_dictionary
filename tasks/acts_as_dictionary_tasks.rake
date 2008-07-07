namespace :dict do
  desc "Generate dictionaries for all models"
  task :generate => :environment do
    # Borrow from ThinkingSphinx's configure.rb
    base = "#{Rails.root}/app/models/"
    Dir["#{base}**/*.rb"].each do |file|
      model_name = file.gsub(/^#{base}([\w_\/\\]+)\.rb/, '\1')      
      # Hack to skip all xxx_related.rb files
      next if /_related/i =~ model_name

      klass = begin
        model_name.classify.constantize
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