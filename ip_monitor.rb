#!/usr/bin/env ruby

require 'dotenv'
require 'socket'
require 'net/http'
require 'uri'
require 'json'
require 'logger'

Dotenv.load

class IPMonitor
  # 設定などは定数またはENVから取得
  FETCH_URL = "https://inet-ip.info/ip".freeze
  
  def initialize
    @webhook_url = ENV.fetch('DISCORD_WEBHOOK_URL')
    @ip_cache_file = ENV.fetch('IP_CACHE_FILE', '.last_ip')
    @ip_icon_url = ENV.fetch('IP_ICON_URL')
    @expected_local_ip = ENV.fetch('EXPECTED_LOCAL_IP')
    @logger = Logger.new($stdout)
  end

  def run
    current_ip = fetch_current_ip
    local_ip = fetch_local_ip
    last_ip = read_last_ip

    # ローカルIPアドレスが期待されているものと違ったら通知
    if local_ip != @expected_local_ip
      notify_discord("🏠 Local IP Address is wrong!: **#{local_ip}**")
      @logger.info "Local IP Address is wrong: #{local_ip}"
      return 
    end
    # ガード節：IPに変更がなければ終了
    if current_ip == last_ip
      @logger.info "IP Address has not changed."
      return 
    end

    @logger.info "IP changed: #{last_ip} -> #{current_ip}"
    
    # グローバルIPに変更があったら通知
    if notify_discord("🏠 Global IP Address Changed: **#{current_ip}**")
      save_ip(current_ip)
    end
  rescue => e
    @logger.error "Unexpected error: #{e.message}"
  end

  private

  def fetch_current_ip
    uri = URI.parse(FETCH_URL)
    response = Net::HTTP.get_response(uri)
    
    unless response.is_a?(Net::HTTPSuccess)
      raise "Failed to fetch IP: #{response.code}"
    end

    response.body.strip
  end

  def fetch_local_ip
    # 実際に通信は行わず、パケットを外に送る際の「自分の出口」のIPを特定する
    udp = UDPSocket.new
    udp.connect("8.8.8.8", 1)
    ip = udp.addr[3]
    udp.close
    ip
  rescue => e
    "Unavailable (#{e.message})"
  end

  def read_last_ip
    return nil unless File.exist?(@ip_cache_file)
    File.read(@ip_cache_file).strip
  end

  def save_ip(ip)
    File.write(@ip_cache_file, ip)
  end

  def discord_payload(msg)
    {
      content: msg,
      username: "IP Monitor",
      avatar_url: @ip_icon_url
    }.to_json
  end

  def notify_discord(msg)
    uri = URI.parse(@webhook_url)
    
    # シンプルな Post リクエストの書き方
    response = Net::HTTP.post(
      uri,
      discord_payload(msg),
      "Content-Type" => "application/json"
    )

    if response.code == '204'
      @logger.info "Notification sent to Discord."
      true
    else
      @logger.error "Discord notification failed: #{response.code} #{response.body}"
      false
    end
  rescue => e
    @logger.error "Network error during Discord notification: #{e.message}"
    false
  end
end

# 実行
if __FILE__ == $0
  IPMonitor.new.run
end
