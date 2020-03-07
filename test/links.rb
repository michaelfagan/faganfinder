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
      .reject{|l| l['status'] == '200' || l['url'].include?('test')}
      .map do |l|
        u = l['url'].gsub('&', '&amp;')
        "<li><a href=\"#{u}\">#{u}</a> #{l['status']} #{l['redirect']} (#{l['pages'].join(', ')})</li>"
      end.join
    File.write 'test/bad_links.html', "<html><head><title>possible broken links</title></head><body><ol>#{html}</ol></body></html>"
  end

  def self.found_urls(urls, page)
    @@urls_found ||= []
    @@urls_found.concat urls.map{|u| [u, page]}
  end


  # take the links which have been found,
  # 1) if they are new, check them and save the info
  # 2) if there are saved links that were not found, remove them
  def self.update
    unique_urls = @@urls_found.map{|u| u[0]}.uniq
    urls = read_links_file
    urls.delete_if do |link|
      if unique_urls.include? link['url']
        unique_urls.delete link['url']
        false
      else
        true
      end
    end
    urls.concat unique_urls.map{|u| check({'url' => u})}

    # update the pages listed on each
    urls.each do |u|
      u['pages'] = @@urls_found.select{|f| f[0]==u['url']}.map{|f|f[1]}.uniq.sort
    end

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

  def self.check(link, debug = false)
    puts "checking " + link['url'] if debug
    url = link['url']
    url += '/' if url =~ /\/\/[^\/]+$/ # can't parse URL without trailing slash
    parsed = URI.parse url
    aborted = false
    begin
      # todo: rewrite these two requests into one

      request = Net::HTTP.new parsed.host
      response = request.request_head parsed.path
      link['status'] = response.code
      if response['location'] && response['location'] != link['url']
        link['redirect'] = response['location']
      end

      Net::HTTP.get(parsed) =~ /<title>(.*?)<\/title>/
      if $1
        if $1.encoding.to_s == 'UTF-8'
          link['title'] = $1
        else
          link['title'] = $1.encode('UTF-8', invalid: :replace)
        end
      elsif link['title']
        link.delete 'title'
      end
    rescue Exception => e
      if e.message == 'abort then interrupt!'
        aborted = true
      else
        link['status'] = e.message
      end
    end
    link['checked'] = Time.now.to_i unless aborted
    link
  end

  # check the links specified
  def self.check_matching(limit = false)
    links = read_links_file
    # do the longest-ago-checked first
    links_to_check = links.select{|l| yield l}.sort_by{|l| l['checked'] }
    limit = (limit || links_to_check.length) - 1
    links_to_check[0..limit].each do |s|
      links[links.index{|l|l['url']==s['url']}] = check(s, true)
      # resave after each in case the code is halted midway
      write_links_file links
    end
    nil
  end

  def self.check_all
    check_matching {|l| true}
  end

  def self.check_some
    check_matching(10) {|l| true}
  end

  def self.check_timeouts
    check_matching {|l| l['status'] == 'Net::ReadTimeout' || l['status'].include?('timed') }
  end

  def self.check_page(page)
    check_matching {|l| l['pages'].include? page }
  end

end