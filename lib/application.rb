require 'mobb/base'
require_relative './bootstrap.rb'

class RutanBot < Mobb::Base
  register ::Extensions::TalkRendererExtension
  register ::Extensions::MemoryCacheExtension

  # settings
  set :name, ENV['BOT_NAME'] || 'rutan_bot'
  set :service, 'power_slack'

  register_render_file File.expand_path('../script.yml', __FILE__)

  helpers do
    def do_search_and_post(search_word)
      search_word.search!.each do |result|
        @env.slack_service.post(
          channel: search_word.channel_id,
          text: result.url
        )
        sleep 0.2
      end
    end
  end

  set(:on_message) do |_|
    condition {@env.kind_of?(::Handlers::PowerSlackMessageReceive)}
  end

  set(:on_event) do |_|
    condition {@env.kind_of?(::Handlers::PowerSlackEventReceive)}
  end

  DEVASATION_CHANNELS = (ENV['DEVASATION_CHANNELS'] || '').split(/\s*,\s*/).uniq

  set(:in_devastations) do |_|
    condition do
      channel = @env.try(:channel)
      channel && DEVASATION_CHANNELS.include?(channel.id)
    end
  end

  set(:to_notify) do |_|
    dest_condition do |res|
      res.last[:channel] = ENV['NOTIFY_CHANNEL']
    end
  end

  on /ping/, reply_to_me: true do
    render 'ping.pong'
  end

  on '日経平均' do
    "https://chart.yahoo.co.jp/?code=998407.O&tm=1d&_ts=#{Time.now.to_i}"
  end

  on '9468' do
    "https://chart.yahoo.co.jp/?code=9468.T&tm=1d&_ts=#{Time.now.to_i}"
  end

  on /\Achart\s*(\d+)\z/ do |code|
    "https://chart.yahoo.co.jp/?code=#{code}.T&tm=1d&_ts=#{Time.now.to_i}"
  end

  on /\s*ganbare\s+add\s+:([^\:]+):(?:\s+([^\s]+)\s+(.+)$)?/, reply_to_me: true do |emoji, name, text|
    cheering = ::Models::Cheering.new(
      emoji: emoji.to_s,
      name: name.to_s,
      text: text.to_s
    )
    if cheering.save
      render 'ganbare.add.success', locals: {cheering: cheering}
    else
      render 'ganbare.add.error', locals: {cheering: cheering}
    end
  end

  on /\s*ganbare\s+remove\s+:([^\:]+):/, reply_to_me: true do |emoji|
    cheering = ::Models::Cheering.find_by(emoji: emoji)
    if cheering
      cheering.destroy
      render 'ganbare.remove.success', locals: {cheering: cheering}
    else
      render 'ganbare.remove.error'
    end
  end

  on /(つら|ツラ|辛)(い|イ|たん)/, in_devastations: true do
    cheering = ::Models::Cheering.pick_random
    if cheering
      @env.slack_service.post(
        channel: @env.channel.id,
        emoji: cheering.emoji,
        name: cheering.name.empty? ? 'ganbare_bot' : cheering.name,
        text: cheering.text.empty? ? '甘えんなカス' : cheering.text,
        as_user: false
      )
    end
  end

  on /エゴサ設定\s(.+)/, reply_to_me: true do |keyword|
    next unless ::Models::SearchWords.usable_twitter?

    unless @env.user.id == ENV['OWNER_USER_ID']
      return render 'ego_search.forbidden'
    end

    search_word = ::Models::SearchWords.find_or_initialize_by(channel_id: @env.channel.id)
    search_word.keyword = keyword
    if search_word.save
      search_word.update_since_id!
      render 'ego_search.success', locals: { keyword: keyword.strip }
    else
      render 'ego_search.error'
    end
  end

  on /echo\s+(.+)/, reply_to_me: true do |match|
    match
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

  on 'emoji_changed', on_event: true, to_notify: true do
    case @env.raw.subtype
    when 'add'
      render 'event.emoji_changed.add',
             locals: {emoji: @env.raw}
    when 'remove'
      render 'event.emoji_changed.remove',
             locals: {emoji: @env.raw}
    end
  end

  on 'subteam_created', on_event: true, to_notify: true do
    render 'event.subteam_created',
            locals: {subteam: @env.raw.subteam}
  end

  on 'subteam_updated', on_event: true, to_notify: true do
    render 'event.subteam_updated',
            locals: {subteam: @env.raw.subteam}
  end

  on 'team_join', on_event: true, to_notify: true do
    render 'event.team_join',
            locals: {user: @env.raw.user}
  end

  on 'user_change', on_event: true, to_notify: true do
    old_user = @env.slack_service.find_user(@env.raw.user.id)
    if @env.raw.user.deleted != old_user.deleted
      if @env.raw.user.deleted
        render 'event.user_change.deleted',
                locals: {user: @env.raw.user}
      else
        render 'event.user_change.activate',
                locals: {user: @env.raw.user}
      end
    end
  end

  cron '* * * * *' do
    next unless ::Models::SearchWords.usable_twitter?

    size = ::Models::SearchWords.count
    next if size == 0

    index = memory_cache[:search_index] || 0
    index = (index + 1) % size
    memory_cache[:search_index] = index

    search_word = ::Models::SearchWords.order(id: :asc).offset(index).first
    do_search_and_post(search_word)
    nil
  rescue => e
    puts e.inspect
  end
end
