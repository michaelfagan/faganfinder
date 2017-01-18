require 'erubis'
require 'htmlcompressor'
require 'html5_validator/validator'
require 'sass'
require 'uglifier'
require_relative 'page'
require_relative 'test/links'
require_relative 'test/spelling'


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

Page.ids.each do |pid|

  # other data for the template
  puts pid
  begin
    page = Page.new pid
  rescue Exception => e
    has_error e.message
  end

  # generate html from the template
  html = Erubis::Eruby.new(File.read 'index.erb.html').result(binding())

  # validate the html
  html_errors = Html5Validator::Validator.new.validate_text html
  if html_errors.any?
    html_errors.map!{|e| "line #{e['lastLine']} #{e['message']}\n\t" + e['extract'].sub(/\n/, "\n\t") }
    html_errors.unshift "HTML validation errors"
    has_error html_errors.join "\n\n"
  end

  # compress the html
  html = HtmlCompressor::Compressor.new.compress html

  # get text and links for checking
  Spelling.find_text_from_html html
  page.groups.each do |group|
    Link.found_urls group.tools.map{|tool| tool.searchUrl.sub('{searchTerms}', 'test')}
  end
  Link.find_urls_from_html page.content

  # all done, output html file
  output_path  = "dist/#{page.id}.html"
  File.write output_path, html
  puts "  saved to #{output_path}"

end

# check links and spelling
Link.update
Spelling.check