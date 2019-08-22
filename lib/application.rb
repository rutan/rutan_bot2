require 'mobb/base'
require_relative './bootstrap.rb'

class RutanBot < Mobb::Base
  register ::Extensions::TalkRendererExtension

  # settings
  set :name, ENV['BOT_NAME'] || 'rutan_bot'
  set :service, 'power_slack'

  register_render_file File.expand_path('../script.yml', __FILE__)

  set(:on_message) do |_|
    condition {@env.kind_of?(::Handlers::PowerSlackMessageReceive)}
  end

  set(:on_event) do |_|
    condition {@env.kind_of?(::Handlers::PowerSlackEventReceive)}
  end

  set(:to_notify) do |_|
    dest_condition do |res|
      res.last[:channel] = ENV['NOTIFY_CHANNEL']
    end
  end

  on /ping/, reply_to_me: true do
    render 'ping.pong'
  end

  on 'bot_added', on_event: true, to_notify: true do
    render 'event.bot_added', locals: {bot: @env.raw.bot}
  end

  on 'bot_changed', on_event: true, to_notify: true do
    render 'event.bot_changed', locals: {bot: @env.raw.bot}
  end

  on 'channel_archive', on_event: true, to_notify: true do
    channel = @env.slack_service.find_channel(@env.raw.channel)
    render 'event.channel_archive', locals: {channel: channel}
  end

  on 'channel_created', on_event: true, to_notify: true do
    render 'event.channel_created', locals: {channel: @env.raw.channel}
  end

  on 'channel_deleted', on_event: true, to_notify: true do
    channel = @env.slack_service.find_channel(@env.raw.channel)
    next unless channel
    render 'event.channel_deleted', locals: {channel: channel}
  end

  on 'channel_rename', on_event: true, to_notify: true do
    old_name = @env.slack_service.find_channel(@env.raw.channel.id)&.name
    render 'event.channel_rename',
           locals: {channel: @env.raw.channel, old_name: old_name}
  end

  on 'channel_unarchive', on_event: true, to_notify: true do
    channel = @env.slack_service.find_channel(@env.raw.channel)
    render 'event.channel_unarchive',
           locals: {channel: channel}
  end
end
