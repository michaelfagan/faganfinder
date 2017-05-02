require 'uri'
require 'net/http'
require 'json'

class Link

  @@urls_found # to hold queue to be handled by self.update
  @@links_path = 'test/links.json'

  def self.valid_format?(url)
    valid = false
    begin
      parsed = URI.parse url
      valid = true if !parsed.host.nil? && parsed.is_a?(URI::HTTP)
    rescue
    end
    valid
  end

  def self.read_links_file
    JSON.parse File.read(@@links_path)
  end

  def self.write_links_file(links)
    # all links
    File.write @@links_path, JSON.pretty_generate(links)
    # bad links only go into HTML page so it's easy to test manually
    html = links
      .reject{|l| l['status'] == '200'}
      .map do |l|
        u = l['url'].gsub('&', '&amp;')
        "<li><a href=\"#{u}\">#{u}</a> #{l['status']} #{l['redirect']}</li>"
      end.join
    File.write 'test/bad_links.html', "<html><head><title>possible broken links</title></head><body><ol>#{html}</ol></body></html>"
  end

  def self.found_urls(urls)
    @@urls_found ||= []
    @@urls_found.concat urls
  end


  # take the links which have been found,
  # 1) if they are new, check them and save the info
  # 2) if there are saved links that were not found, remove them
  def self.update
    @@urls_found.uniq!
    urls = read_links_file
    urls.delete_if do |link|
      if @@urls_found.include? link['url']
        @@urls_found.delete link['url']
        false
      else
        true
      end
    end
    urls.concat @@urls_found.map{|u| check u}

    # check for invalid urls
    urls = urls.partition{|u| valid_format? u['url'] }
    if urls[1].length > 0
      raise 'invalid URL(s): ' + urls[1].map{|u| u['url']}.join("\n")
    end
    urls = urls[0]

    urls.sort_by! do |l|
      # keep a consistent ordering
      u = URI.parse l['url']
      u.host.split('.').reverse.join + u.path + (u.query || '') + (u.fragment || '') + u.scheme
    end
    write_links_file urls
  end

  def self.check(url, debug = false)
    puts "checking #{url}" if debug
    result = { 'url' => url }
    parsed = URI.parse url
    begin
      # todo: rewrite these two requests into one

      request = Net::HTTP.new parsed.host
      response = request.request_head parsed.path
      result['status'] = response.code
      if response['location'] && response['location'] != url
        result['redirect'] = response['location']
      end

      Net::HTTP.get(parsed) =~ /<title>(.*?)<\/title>/
      result['title'] = $1.force_encoding('UTF-8') if $1
    rescue Exception => e
      puts "  #{e.message}"
      result['status'] = 'timeout'
    end
    result
  end

  def self.check_all
    links = read_links_file.map{|l| check l['url'], true}
    write_links_file links
  end

  def self.recheck_timeouts
    links = read_links_file.map do |l|
      l['status'] == 'timeout' ? check(l['url'], true) : l
    end
    write_links_file links
  end

end