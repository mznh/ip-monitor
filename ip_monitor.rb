#!/usr/bin/env ruby

require 'dotenv'
require 'net/http'
require 'uri'
require 'json'

Dotenv.load

class IPMonitor
  def initialize
    @webhook_url = ENV['DISCORD_WEBHOOK_URL']
    @ip_cache_file = ENV['IP_CACHE_FILE']
  end

  def run
    current_ip = get_my_ip_address()
    last_ip = read_last_ip()

    if current_ip != last_ip then
      notify_discord(current_ip)
      save_ip(current_ip)
    end
  end

  def get_my_ip_address()
    uri = URI.parse("https://inet-ip.info/ip")
    my_ip = Net::HTTP.get_response(uri)
    my_ip.body # response body
  end

  def read_last_ip
    File.exist?(@ip_cache_file) ? File.read(@ip_cache_file).strip : nil
  end

  def save_ip(ip)
    File.write(@ip_cache_file, ip)
  end

  def discord_payload msg
    payload = {
      content: msg.to_s, # メッセージ本文
      username: "IPMonitor", 
      avatar_url: "https://www.ruby-lang.org/images/header-ruby-logo.png" # アイコン（任意）
    }.to_json
    payload
  end
  def notify_discord msg
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true # DiscordはHTTPS必須

    request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => 'application/json'})
    request.body = discord_payload(msg)
    response = http.request(request)

    if response.code == '204' # DiscordのWebhook成功時は204(No Content)が返る
      puts "送信成功！"
    else
      puts "失敗しました: #{response.code} #{response.body}"
    end
  end
end

ip_monitor = IPMonitor.new()
ip_monitor.run()
