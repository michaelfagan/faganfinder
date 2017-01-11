# invalid URLs are caught before they are added to @@urls_found

require 'uri'
require 'net/http'
require 'json'

class Link

  @@urls_found # to hold queue to be handled by self.update
  @@links_path = 'test/links.json'

  def self.read_links_file
    JSON.parse File.read(@@links_path)
  end

  def self.write_links_file(links)
    File.write @@links_path, JSON.pretty_generate(links)
  end

  def self.found_urls(urls)
    @@urls_found ||= []
    @@urls_found.concat urls
  end

  def self.find_urls_from_html(html)
    found_urls URI.extract(html, /http(s)?/).map{|u| u.gsub('&amp;', '&')}
  end

  # take the links which have been found,
  # 1) if they are new, check them and save the info
  # 2) if there are saved links that were not found, remove them
  def self.update
    @@urls_found.uniq!
    existing_links = read_links_file
    existing_links.delete_if do |link|
      if @@urls_found.include? link['url']
        @@urls_found.delete link['url']
        false
      else
        true
      end
    end
    existing_links.concat @@urls_found.map{|u| check u}
    existing_links.sort_by! do |l|
      # keep a consistent ordering
      u = URI.parse l['url']
      u.host.split('.').reverse.join + u.path + (u.query || '') + (u.fragment || '') + u.scheme
    end
    write_links_file existing_links
  end

  def self.check(url)
    puts "checking #{url}"
    result = { 'url' => url }
    parsed = URI.parse url
    begin
      request = Net::HTTP.new parsed.host
      response = request.request_head parsed.path
      result['status'] = response.code
      if response['location'] && response['location'] != url
        result['redirect'] = response['location']
      end
    rescue
      result['status'] = 'timeout'
    end
    result
  end

  def self.check_all
    links = read_links_file.map{|l| check l['url']}
    write_links_file links
  end

end