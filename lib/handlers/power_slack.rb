require 'cgi'
require 'slack-ruby-client'

module Handlers
  class PowerSlackMessageReceive < ::Repp::Event::Receive
    interface :channel, :user, :type, :ts, :reply_to, :raw, :slack_service

    def bot?
      !!@is_bot
    end

    def bot=(switch)
      @is_bot = switch
    end
  end

  class PowerSlackEventReceive < ::Repp::Event::Receive
    interface :type, :raw, :slack_service

    def body
      type.to_s
    end

    def reply_to
      []
    end
  end

  class PowerSlackTickerEvent < ::Repp::Event::Ticker
    interface :slack_service
  end

  class PowerSlackTicker < ::Repp::Ticker
    attr_accessor :slack_service

    def run!
      @task = Concurrent::TimerTask.new(execution_interval: 1) do
        next unless slack_service
        @block.call(Task.new.tick(PowerSlackTickerEvent.new(
          body: Time.now,
          slack_service: slack_service
        )))
      end
      @task.execute
    end
  end

  class SlackService
    attr_reader :web_client

    def initialize(web_client)
      @web_client = web_client
      refresh
    end

    def refresh
      refresh_users_cache
      refresh_channel_caches
    end

    def refresh_users_cache
      @user_caches = {}

      resp = web_client.users_list
      return unless resp.ok
      resp.members.each do |member|
        @user_caches[member.id] = member
      end
    end

    def refresh_user_cache(uid)
      resp = web_client.users_info(user: uid)
      @user_caches[uid] = resp.ok ? resp.user : nil
    end

    def find_user(uid)
      return @user_caches[uid] if @user_caches.key?(uid)
      refresh_user_cache(uid)
    end

    def find_user_by_cache(uid)
      @user_caches[uid]
    end

    def refresh_channel_caches
      @channel_caches = {}

      resp = web_client.conversations_list
      return unless resp.ok
      resp.channels.each do |channel|
        @channel_caches[channel.id] = channel
      end
    end

    def find_channel(uid)
      return @channel_caches[uid] if @channel_caches.key?(uid)

      resp = web_client.conversations_info(channel: uid)
      return @channel_caches[uid] = resp.channel if resp.ok

      resp = web_client.groups_info(channel: uid)
      return @channel_caches[uid] = resp.group if resp.ok

      @channel_caches[uid] = nil
    end

    def post(text:, channel:, attachments: [], as_user: true, name: nil, emoji: nil)
      web_client.chat_postMessage({
        text: text,
        channel: channel,
        as_user: as_user,
        username: name,
        icon_emoji: ":#{emoji}:",
        attachments: attachments
      }.delete_if {|_, v| v.nil?})
    end
  end

  class PowerSlack
    def initialize(app, options)
      @app = app
      @options = options
      setup_token
    end

    def run
      @application = @app.new
      init_ticker
      connect!
    end

    def stop
    end

    private

    def setup_token
      ::Slack.configure do |config|
        config.token = ENV['SLACK_TOKEN']
      end
    end

    def reset_client
      @web_client = nil
      @rtm_client = nil
      @slack_service = nil
    end

    def web_client
      @web_client ||= ::Slack::Web::Client.new
    end

    def rtm_client
      @rtm_client ||= ::Slack::RealTime::Client.new
    end

    def init_ticker
      @ticker = PowerSlackTicker.task(@application) do |res|
        post_message(res)
      end
      @ticker.slack_service = slack_service
      @ticker.run!
    end

    def connect!
      begin
        reset_client
        bind_events
        rtm_client.start!
      rescue => e
        puts e.inspect
        rtm_client.stop! rescue nil
        sleep 1
      end
    end

    def slack_service
      @slack_service ||= SlackService.new(web_client)
    end

    def bind_events
      rtm_client.on :message, &method(:on_message)

      %i[
        bot_added
        bot_changed
        channel_archive
        channel_created
        channel_deleted
        channel_rename
        channel_unarchive
        commands_changed
        dnd_updated_user
        emoji_changed
        member_joined_channel
        member_left_channel
        pin_added
        pin_removed
        reaction_added
        reaction_removed
        subteam_created
        subteam_members_changed
        subteam_updated
        team_join
        user_change
      ].each {|type| rtm_client.on type, &method(:on_event)}
    end

    def on_message(message)
      return unless message.user

      from_user = slack_service.find_user(message.user)
      channel = slack_service.find_channel(message.channel)
      reply_to = (message.text || '').scan(/<@(\w+?)>/).map do |node|
        u = slack_service.find_user(node.first)
        u ? u.name : nil
      end

      receive = PowerSlackMessageReceive.new(
        type: message.type,
        body: format_text(message.text),
        channel: channel,
        user: from_user,
        ts: message.ts,
        reply_to: reply_to.compact,
        raw: message,
        slack_service: slack_service
      )

      process_receive(receive)
    end

    def on_event(message)
      receive = PowerSlackEventReceive.new(
        type: message.type,
        raw: message,
        slack_service: slack_service
      )
      process_receive(receive)

      case message.type
      when 'channel_rename'
        slack_service.refresh_channel_caches
      when 'user_change'
        if message&.user&.id
          slack_service.refresh_user_cache(message.user.id)
        else
          slack_service.refresh_users_cache
        end
      end
    end

    def process_receive(receive)
      res = @application.call(receive)
      post_message(res, receive)
    end

    def post_message(res, receive = nil)
      return unless res
      return unless res.first
      channel_to_post = res.last && res.last[:channel] || receive&.channel&.id
      return unless channel_to_post
      attachments = res.last && res.last[:attachments]

      web_client.chat_postMessage(
        text: res.first,
        channel: channel_to_post,
        as_user: true,
        attachments: attachments
      )
    end

    def format_text(src_text)
      text = src_text.to_s.dup
      text.gsub!(/\\b/, '')
      text.gsub!(/\<\@(U[^>\|]+)\>/) do
        "@#{username_by_uid(Regexp.last_match(1))}"
      end
      text.gsub!(/\<\@(U[^\|]+)\|([^>]+)\>/) do
        "@#{username_by_uid(Regexp.last_match(1))}"
      end
      text.gsub!(/\<\#(C[^>\|]+)\>/) do
        c = slack_service.find_channel(Regexp.last_match(1))
        "##{c ? c.name : c}"
      end
      text.gsub!(/\<\#(C[^\|]+)\|([^>]+)\>/) do
        c = slack_service.find_channel(Regexp.last_match(1))
        "##{c ? c.name : c}"
      end
      text.gsub!(/<[^\|>]+\|([^>]+)>/, '\1')
      text.gsub!(/<|>/, '')
      text.gsub!(/\!(here|channel|group)/, '@\1')
      CGI.unescapeHTML(text)
    end

    def username_by_uid(uid)
      user = slack_service.find_user(uid)
      return uid unless user
      if user.profile && user.profile.display_name.to_s.size > 0
        user.profile.display_name
      else
        user.name
      end
    end

    class << self
      def run(app, options = {})
        handler = PowerSlack.new(app, options)
        yield handler if block_given?
        handler.run
      end
    end
  end
end

Repp::Handler.register 'power_slack', Handlers::PowerSlack
