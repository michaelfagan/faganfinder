require 'erubis'
require 'htmlcompressor'
require 'html5_validator/validator'
require 'sassc'
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
  css = SassC::Engine.new(File.read('index.scss.css'), syntax: :scss, style: :compressed).render.strip
rescue Exception => e
  has_error "SCSS error: #{e.message}"
end

# compile js
begin
  js = Uglifier.new.compile File.read('index.js')
rescue Exception => e
  has_error "JavaScript error: #{e.message}"
end

site = {
  name: 'Fagan Finder', # repeated in dist/search.php
  root: 'https://www.faganfinder.com/',
  email: 'michael@faganfinder.com',
  ga: 'UA-13006445-2' # repeated in dist/search.php
}
site[:root_old] = site[:root].sub 'https', 'http'

pages = Page.ids.map{|pid| Page.new pid }

html_validator_error = false

pages.each do |page|

  # other data for the template
  puts page.id
  begin
    page.load
  rescue Exception => e
    has_error e.message
  end

  # generate html from the template
  html = Erubis::Eruby.new(File.read 'index.erb.html').result(binding())

  # validate the html
  unless html_validator_error
    begin
      html_errors = Html5Validator::Validator.new.validate_text html
      if html_errors.any?
        html_errors.map!{|e| "line #{e['lastLine']} #{e['message']}\n\t" + e['extract'].sub(/\n/, "\n\t") }
        html_errors.unshift "HTML validation errors"
        has_error html_errors.join "\n\n"
      end
    rescue
      html_validator_error = true
      puts '  Unable to validate HTML, must check manually'
    end
  end

  # compress the html
  html = HtmlCompressor::Compressor.new.compress html

  # get text and links for checking
  Spelling.find_text_from_html html
  Link.found_urls page.external_links, page.id

  # all done, output html file
  output_path  = "dist/#{page.id}.html"
  File.write output_path, html
  puts "  saved to #{output_path}"

end

# check spelling and links
Spelling.check
begin
  Link.update
rescue Exception => e
  has_error e.message
end