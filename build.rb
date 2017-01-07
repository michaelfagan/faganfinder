require 'erubis'
require 'json'
require 'htmlcompressor'
require 'html5_validator/validator'
require 'sass'
require 'uglifier'

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

  # all done, output html file
  output_path  = "dist/#{page_id}.html"
  File.write output_path, html
  puts "saved to #{output_path}"

end