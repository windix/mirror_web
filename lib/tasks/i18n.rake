require 'open-uri'

namespace :i18n do
  desc "Update latest default rails locales file from github"
  task :update_default => :environment do
    # available_locales
    RAILS_DEFAULT_LOCALE_PATH = "#{RAILS_ROOT}/config/locales/default"

=begin    
    content = open('http://github.com/svenfuchs/rails-i18n/raw/master/rails/locale/zh-CN.yml').read
    content.sub! 'zh-CN', 'zh'
    
    File.open("#{RAILS_DEFAULT_LOCALE_PATH}/zh.yml", 'w') do |f|
      f.write content
    end
=end

    to_download = [ 'zh-CN', 'zh-TW' ]

    to_download.each do |locale|
      system "wget http://github.com/svenfuchs/rails-i18n/raw/master/rails/locale/#{locale}.yml -P #{RAILS_DEFAULT_LOCALE_PATH} -N"
    end
  end
end
