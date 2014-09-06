require 'bundler/setup'
require 'sidekiq'
require 'dropbox_sdk'

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
    meta = @client.metadata(from, nil, nil, nil, nil, nil, true)
    meta['contents'].each do |c|
      if c['is_dir']
        sort(c['path'], to_root)
      elsif c['mime_type'] == 'image/jpeg'
        raw_date = c['photo_info'] && c['photo_info']['time_taken'] || c['client_mtime']
        date = DateTime.parse(raw_date)
        from = c['path']
        to = "#{to_root}/#{date.year}/#{date.month} #{MONTHS[date.month - 1]} - #{date.year}/#{File.basename(from, '.*')}.jpg"
        @client.file_move(from, to)
        yield(from, to) if block_given?
      elsif c['mime_type'] == 'video/quicktime'
        from = c['path']
        to = "#{to_root}/Videos/#{File.basename(from)}"
        @client.file_move(from, to)
        yield(from, to) if block_given?
      end
    end
  end
end

class SortWorker
  include Sidekiq::Worker

  def perform
    client = DropboxClient.new(ENV['DROPBOX_ACCESS_TOKEN'])
    sorter = DropboxSort.new(client)
    logger ||= Logger.new(STDOUT)
    logger.info 'Start sorting'
    sorter.sort('/Camera Uploads', '/Pictures') { |src, dest|
      logger.info "#{src} -> #{dest}"
    }
    logger.info 'End sorting'
  end
end
