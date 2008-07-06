namespace :dict do
  desc "Generate dictionaries for all models"
  task :generate => :environment do
    models_root = File.join(Rails.root, "app", "models")
    Dir.new(models_root).each do |model_file|
      if model_file.match(/\.rb$/)
        model = model_file.gsub(/\.rb$/, '').camelize
        klass = eval(model)
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