#!/usr/bin/env ruby
#
# ruby-site-crawler v0.4
# 
# @version  $Id$
# @author   Nico Puhlmann <nico.puhlmann@gmail.com>
#
# This simple crawler crawls a website and stores
# all internal linked urls in a sqlite database.
# You can use this to create a google sitemap
# for example.
#
# Please look in crawler.yml for configuration
#
# Example crawler.yml file:
#
# config:
#  standard_uri: http://www.yousite.com/
#  exclude_regex: \?*?(sort=|backlink=|SID=|.css)
#
# How to create a sitemap with this crawler?
#
# Make sure you have a configured crawler.yml and
# for google a sitemap_gen.py script with a configured 
# config.xml with urllist support:
# <urllist  path="urllist.txt"  encoding="UTF-8"  />)
#
# Just take a coffee and run the following commands on your shell:
#
# ruby crawler.rb
# ruby crawler.rb urllist > urllist.txt # < this generates the urllist
# python sitemap_gen.py --config=config.xml
#
# Now urllist sitemap should be generated and google 
# notified about this update. Have fun!
#
#
require 'net/http'
require 'socket'
require 'rubygems'
require 'sqlite3'
require 'htmlentities'
require 'yaml'


class Header
  attr_reader :header
  attr_reader :protocol
  attr_reader :code
  attr_reader :text

  def initialize(header)
    @header = {}

    if not header.nil?
      firstline, rest = header.split(/\r*\n/, 2)

      @protocol, @code, @text = firstline.split(/  */, 3)

      @code = @code.to_i

      if not rest.nil?
        rest.split(/\r*\n/).each do |line|
          key, value  = line.split(/ /, 2)
          @header[key.sub(/:$/, "").downcase] = value
        end
      end
    end
  end

  def to_s
    res = ""

    res << "%s %s %s\n" % [@protocol, @code, @text]

    @header.each do |k, v|
      res << "%s=%s\n" % [k, v]
    end

    return res
  end
end

def crawler
  
  threads = []
  num = $db.get_first_value( "SELECT count(*) num FROM urls;" )
  if num == "0"
    $db.execute "INSERT INTO urls (url, fetched) VALUES ('#{@config['standard_uri']}', 0)"
    puts "Created standard entry, please rerun crawler\n";
  else
    while (num = $db.get_first_value( "SELECT count(*) num FROM urls WHERE fetched = 0" )).to_i > 0
      puts "Starting to fetch #{num} url's...";
      threads = []
      $db.execute("SELECT url FROM urls WHERE fetched = 0 LIMIT 100").each do |r|
        threads << Thread.new do
          begin
            fetch_url(r.first)
          rescue
            nil
          end
        end
      end
      threads.each { |thread|  
        thread.join
      }
    end
  end
end

def fetch_url(urltofetch)
  if %r{http://([^/]+)/(.*)}i =~ urltofetch
    domain, path = $1, $2
  end
   
  proto = "http";
  fetchurl = proto+"://"+domain+"/"+path
  print "Fetching " + fetchurl + "\n"
  
  if proto=="http" 
    begin 
      t = TCPSocket.new(domain, 'http') 
    rescue 
      puts "error: #{$!}" 
    else 
      t.print "GET /"+path+" HTTP/1.0\r\n" 
      t.print "User-Agent: Urllister 1.0\r\n" 
      t.print "Host: "+domain+"\r\n\r\n" 
      answer = t.gets(nil) 
      t.close 
    end
    header, data  = nil, nil
    header, data  = answer.split(/\r*\n\r*\n/, 2)  if not answer.nil?
    header    = Header.new(header)

    urls = []

    if not header.header["location"].nil? and header.header["location"] != "/" + path
      if %r{^https://}i =~ header.header["location"] 
        url = nil
      elsif %r{^http://}i =~ header.header["location"]
        url = nil
      else
        url = proto + "://" + domain + header.header["location"]
      end
      if not url.nil?
        urls << url.gsub(/[?|&]SID=[a-zA-Z0-9-]{32}/, "")
      end
    end
    answer.scan(/href="?'?(#{proto}:\/\/#{domain})?\/([^"'#]+)"?'?/) { 
      urls << (proto+"://"+domain+"/"+$2).decode_entities
      #puts url
    }
    
    urls.each do |url|
      re = Regexp.compile(@config['exclude_regex'])
      if re.match(url)
        # nothing
        #puts "found match with #{url}\n"
      elsif ($db.get_first_value("SELECT count(*) num FROM urls WHERE url = ?", url)).to_i == 0
        $db.execute "REPLACE INTO urls (url, fetched) VALUES ('#{url}', 0)"
      end
    end
    $db.execute "UPDATE urls SET fetched = 1 WHERE url = ?", fetchurl
  end
end

def get_urllist
  $db.execute("SELECT url FROM urls ORDER BY id ASC").each do |r|
      puts r.first + "\n"
  end  
end

def connect
  SQLite3::Database.new( 'urls.db' )
end

# Main program
@config = YAML.load_file("./crawler.yml")['config']
if @config.nil? || @config['exclude_regex'].nil? || @config['standard_uri'].nil?
  puts "Please specifiy a standard_uri and exclude_regex in crawler.yml!\n"
  exit
end

if( !File.exists?( 'urls.db' ) )

$db = SQLite3::Database.new( 'urls.db' )
$db.execute <<SQL

  CREATE TABLE urls (
   id INTEGER PRIMARY KEY,
   url TEXT UNIQUE,
   fetched INTEGER
  );
 
SQL
$db.execute "REPLACE INTO urls (url, fetched) VALUES ('#{@config['standard_uri']}', 0)"
else
 $db = connect
end

if ARGV[0] == "urllist"
  get_urllist
else
  puts "[" + Time.now.strftime("%Y-%m-%d %H:%M:%S") + "] Crawler starting..\n"
  crawler
  puts "[" + Time.now.strftime("%Y-%m-%d %H:%M:%S") + "] Crawler ending..\n"
end

$db.close

