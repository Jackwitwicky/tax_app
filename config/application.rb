require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TaxApp
  class Application < Rails::Application
    if defined?(FactoryBotRails)
      initializer after: "factory_bot.set_factory_paths" do
        require 'spree/testing_support'
        FactoryBot.definition_file_paths = [
          *Spree::TestingSupport::FactoryBot.definition_file_paths,
          Rails.root.join('spec/fixtures/factories'),
        ]
      end
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.to_prepare do
      # Load application prependers
      Dir.glob(Rails.root.join('app', 'prependers', '**', '*.rb')).sort.each do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      Rails.root.join('app', 'prependers', '*').tap do |path|
        prepender_paths = Dir.glob(path).map { |p| File.expand_path(p, __FILE__) }
        Prependers.load_paths(*prepender_paths)
      end
    end
  end
end
