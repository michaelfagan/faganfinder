require 'erubis'
require 'json'
require 'htmlcompressor'
require 'html5_validator/validator'
require 'sass'
require 'uglifier'
require 'nokogiri'
require_relative 'test/links'
require 'ffi/aspell'

def has_error(message)
  message.split(/(\n|\r)+/).each do |s|
    STDERR.puts "  #{s}"
  end
  exit
end


# compile css
begin
  css = Sass::Engine.new(File.read('index.scss.css'), syntax: :scss, style: :compressed).render.strip
rescue Exception => e
  has_error "SCSS error: #{e.message}"
end

# compile js
begin
  js = Uglifier.new.compile File.read('index.js')
rescue Exception => e
  has_error "JavaScript error: #{e.message}"
end


site_name = 'Fagan Finder'

text = '' # to contain text from all pages for spell checking

Dir['./tools/*.json'].each do |file|

  page_id = /.*\/(.+)\.[^\.$]/.match(file)[1]
  puts page_id

  # other data for the template
  tool_groups = JSON.parse File.read(file), object_class: OpenStruct
  page_text = File.read file.sub('json', 'html')

  # validate data
  has_error('no tool groups') if tool_groups.length < 1
  tool_groups.each do |group|
    has_error('group name is absent or too short') if !group.name || group.name.length < 4
    has_error("no tools in group #{group.name}") if !group.tools || group.tools.length < 1
    group.tools.each do |tool|
      has_error("tool name is absent or too short #{tool}") if !tool.name || tool.name.length < 3
      has_error("missing searchUrl for #{tool.name}") if !tool.searchUrl
      begin
        parsed = URI.parse(tool.searchUrl.sub('{searchTerms}', 'test'))
        raise 'badurl' if parsed.host.nil? || !parsed.is_a?(URI::HTTP)
      rescue
        has_error "searchUrl is not a valid url for #{tool.name}"
      end
      unless tool.searchUrl.include?('{searchTerms}') || tool.post
        has_error "missing or bad searchUrl for #{tool.name}"
      end
    end
  end

  # generate html from the template
  html = Erubis::Eruby.new(File.read 'template.erb.html').result(binding())

  # validate the html
  html_errors = Html5Validator::Validator.new.validate_text html
  if html_errors.any?
    html_errors.map!{|e| "line #{e['lastLine']} #{e['message']}\n\t" + e['extract'].sub(/\n/, "\n\t") }
    html_errors.unshift "HTML validation errors"
    has_error html_errors.join "\n\n"
  end

  # compress the html
  html = HtmlCompressor::Compressor.new.compress html

  # extract text for spell checking
  parsed = Nokogiri::HTML html
  parsed.search('//style').each{|node| node.remove} # remove <style>
  parsed.search('//script').each{|node| node.remove} # remove <script>
  # get page text and from title attributes
  text += ' ' + parsed.text
  text += ' ' + parsed.search('//*/@title').map{|t| t.text}.join(' ')
  # extract links for link checking
  tool_groups.each do |group|
    Link.found_urls group.tools.map{|tool| tool.searchUrl.sub('{searchTerms}', 'test')}
  end
  Link.find_urls_from_html page_text

  # all done, output html file
  output_path  = "dist/#{page_id}.html"
  File.write output_path, html
  puts "  saved to #{output_path}"

end

Link.update # check the newly-found links, delete the no-longer-used ones


# spell checking

# text to words
words = text.strip.split(/\W+/).uniq.reject{|w| w =~ /^\d+$/ }.sort_by(&:downcase)
# don't check allowed words
allowed_words_path = 'test/allowed_words.txt'
allowed_words = File.readlines(allowed_words_path).map{|w| w.strip}
found_allowed_words = []
words.reject! do |w|
  allowed = allowed_words.include? w
  found_allowed_words << w if allowed
  allowed
end

# resave allowed words list to remove any words no longer needed
found_allowed_words.sort_by!{|w| w.downcase + w}
File.write allowed_words_path, found_allowed_words.join("\n")

# check each word
speller = FFI::Aspell::Speller.new 'en_CA'
misspelled = []
words.each do |word|
  misspelled << word unless speller.correct? word
end
speller.close

if misspelled.length > 0
  puts "#{misspelled.length} spelling errors"
  puts "  " + misspelled.join("\n  ")
end