require 'nokogiri'
require 'ffi/aspell'


class Spelling

  @@text_found

  def self.found_text(text)
    @@text_found ||= ''
    @@text_found += ' ' + text
  end

  def self.find_text_from_html(html)
    parsed = Nokogiri::HTML html
    parsed.search('//style').each{|node| node.remove} # remove <style>
    parsed.search('//script').each{|node| node.remove} # remove <script>
    # get page text and from title attributes
    found_text parsed.search("//meta[@name='description']/@content").first
    found_text parsed.text
    found_text parsed.search('//*/@title').map{|t| t.text}.join(' ')
  end

  def self.check

    # text to words
    words = @@text_found.gsub(/[^a-zA-Z0-9À-žА-Яа-я\.]+/, ' ').gsub(/\. /, ' ').split(' ').uniq.reject{|w| w =~ /^\d+(th)?$/ }.sort_by(&:downcase)
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
    misspelled = words.reject{|w| speller.correct? w}
    speller.close
    if misspelled.length > 0
      puts "#{misspelled.length} spelling errors"
      puts "  " + misspelled.join("\n  ")
    end

  end

end