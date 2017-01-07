# build.rb already checks URLs for syntax, so this assumes the format is valid

require 'json'
require 'uri'
require 'net/http'


urls_to_check = []

Dir['./tools/*.json'].each do |file|
  # URLs from search tools
  tool_groups = JSON.parse File.read(file), object_class: OpenStruct
  tool_groups.each do |group|
    urls_to_check.concat group.tools.map{|tool| tool.searchUrl.sub('{searchTerms}', 'test')}
  end
  # URLs from links
  html = File.read file.sub('json', 'html')
  urls_to_check.concat URI.extract(html, /http(s)?/).map{|u| u.gsub('&amp;', '&')}
end

urls_to_check.uniq!

problems = []

urls_to_check.each do |url|
  puts "checking #{url}"
  parsed = URI.parse url
  begin
    request = Net::HTTP.new parsed.host
    response = request.request_head parsed.path
    status = response.code
    redirect = response['location']
    redirect = nil if redirect == url # don't try to follow circular redirects
  rescue
    status = 'timeout'
    redirect = nil
  end
  unless status == '200'
    problem = { url: url, status: status }
    problem[:redirect] = redirect if redirect
    problems << problem
  end
end

path = 'test/link_check_results.json'
File.write path, JSON.pretty_generate(problems)

puts "found #{urls_to_check.length} unique URLs"
puts "#{problems.length} had problems"
puts "results saved to #{path}"