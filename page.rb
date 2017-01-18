require 'json'

class Page

  def initialize(path)

    @page = JSON.parse File.read(path), object_class: OpenStruct

    # validate 
    raise('no tool groups') if @page.length < 1
    @page.each do |group|
      raise('group name is absent or too short') if !group.name || group.name.length < 4
      raise("no tools in group #{group.name}") if !group.tools || group.tools.length < 1
      group.tools.each do |tool|
        raise("tool name is absent or too short #{tool}") if !tool.name || tool.name.length < 3
        raise("missing searchUrl for #{tool.name}") if !tool.searchUrl
        begin
          parsed = URI.parse(tool.searchUrl.sub('{searchTerms}', 'test'))
          raise 'bad URL' if parsed.host.nil? || !parsed.is_a?(URI::HTTP)
        rescue
          raise "searchUrl is not a valid URL for #{tool.name}"
        end
        unless tool.searchUrl.include?('{searchTerms}') || tool.post
          raise "missing or bad searchUrl for #{tool.name}"
        end
      end
    end

    # set up generated data
    @id = /.*\/(.+)\.[^\.$]/.match(path)[1]
    @number_of_tools ||= @page.map{|g| g.tools.length }.inject(:+)
    @page.map! do |group|
      group.shortName ||= group.name
      group.id = group.shortName.gsub(/<[^>]+>/, '').gsub(/[^\w]/, '_').downcase
      group
    end

  end

  def groups
    @page
  end

  def id
    @id
  end

  def number_of_tools
    @number_of_tools
  end

end