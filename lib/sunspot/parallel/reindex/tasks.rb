namespace :sunspot do
  SUNSPOT_PARALLEL_REINDEX_ARGNAMES = [:batch_size, :models, :exec_processor_size, :first_id].freeze
  namespace :reindex do
    desc 'Reindex models in parallel'
    task :parallel, SUNSPOT_PARALLEL_REINDEX_ARGNAMES => :environment do |_t, args|
      with_session(Sunspot::SessionProxy::Retry5xxSessionProxy.new(Sunspot.session)) do
        reindex_options = { batch_commit: false,
                            exec_processor_size: Parallel.processor_count,
                            batch_size: 1000 }

        case args[:exec_processor_size]
        when 'false'
          reindex_options[:exec_processor_size] = 1
        when /^\d+$/
          reindex_options[:exec_processor_size] = args[:exec_processor_size].to_i if args[:exec_processor_size].to_i > 0
        end

        case args[:batch_size]
        when 'false'
          reindex_options[:batch_size] = 1000
        when /^\d+$/
          reindex_options[:batch_size] = args[:batch_size].to_i if args[:batch_size].to_i > 0
        end

        reindex_options[:first_id] = args[:first_id] if args[:first_id] =~ /^\d+$/

        puts "#{Parallel.processor_count} processor(s)"
        puts "reindex using #{reindex_options[:exec_processor_size]} processor(s)"

        # Load all the application's models. Models which invoke 'searchable' will register themselves
        # in Sunspot.searchable.
        Rails.application.eager_load!
        Rails::Engine.subclasses.each { |engine| engine.instance.eager_load! }

        if args[:models].present?
          # Choose a specific subset of models, if requested
          model_names = args[:models].split(/[+ ]/)
          sunspot_models = model_names.map(&:constantize)
        else
          # By default, reindex all searchable models
          sunspot_models = Sunspot.searchable
        end

        if args[:first_id].present? && sunspot_models.size > 1
          $stderr.puts 'Error: you are using start_id without specifying a model.'
          exit
        end

        if args[:first_id].present?
          total_documents = models_to_reindex_count(sunspot_models.first, args[:first_id])
          sorted_models   = sunspot_models
        else
          total_documents = sunspot_models.map(&:count).sum
          sorted_models   = sunspot_models.sort { |a, b| a.count <=> b.count }
        end

        # Set up progress_bar to, ah, report progress
        begin
          require 'progress_bar'
          reindex_options[:progress_bar] = ProgressBar.new(total_documents)
        rescue LoadError => _e
          $stdout.puts "Skipping progress bar: for progress reporting, add gem 'progress_bar' to your Gemfile"
        rescue Exception => e
          $stderr.puts "Error using progress bar: #{e.message}"
        end

        $stdout.puts 'Reindex model list:'
        sorted_models.each do |model|
          $stdout.puts " name=#{model.name} record_size=#{models_to_reindex_count(model, args[:first_id])}"
        end
        $stdout.flush

        sorted_models.each do |model|
          if args[:first_id].present?
            puts "Resuming search from id #{args[:first_id]} without removing all models from index..."
          else
            model.solr_remove_all_from_index
          end
          model.solr_index_parallel(reindex_options)
        end
      end
    end

    def models_to_reindex_count(sunspot_model, first_id = nil)
      if first_id
        sunspot_model.where('id >= ?', first_id).count
      else
        sunspot_model.count
      end
    end
  end

  namespace :parallel do
    task :reindex, SUNSPOT_PARALLEL_REINDEX_ARGNAMES do |_, args|
      Rake::Task['sunspot:reindex:parallel'].invoke(*args)
    end
  end
end
