require 'bundler/setup'
require 'sidekiq'
require 'dropbox_api'

Sidekiq.configure_client do |config|
  config.redis = { namespace: 'dropboxorganizer', size: 1 }
end

Sidekiq.configure_server do |config|
  config.redis = { namespace: 'dropboxorganizer' }
end

class DropboxSort
  MONTHS = %w(January February March April May June July August September October November December)

  def initialize(client)
    @client = client
  end

  def sort(from, to_root)
    @client.list_folder(from, include_media_info: true).entries.each do |c|
      from = c.path_lower

      if c.is_a?(DropboxApi::Metadata::Folder)
        sort(c.path_lower, to_root)
      elsif c.is_a?(DropboxApi::Metadata::File)
        if [".jpg", ".jpeg"].include?(File.extname(from))
          date = c.media_info&.time_taken
          next unless date

          to = "#{to_root}/#{date.year}/#{date.month} #{MONTHS[date.month - 1]} - #{date.year}/#{File.basename(from, '.*')}.jpg"
          @client.move(from, to)
          yield(from, to) if block_given?
        elsif File.extname(from) == ".mp4"
          to = "#{to_root}/Videos/#{File.basename(from)}"
          @client.move(from, to)
          yield(from, to) if block_given?
        end
      end
    end
  end
end

class SortWorker
  include Sidekiq::Worker

  def perform
    client = DropboxApi::Client.new(ENV['DROPBOX_ACCESS_TOKEN'])
    sorter = DropboxSort.new(client)
    logger ||= Logger.new(STDOUT)
    logger.info 'Start sorting'
    sorter.sort('/Camera Uploads', '/Pictures') { |src, dest|
      logger.info "#{src} -> #{dest}"
    }
    logger.info 'End sorting'
  end
end
