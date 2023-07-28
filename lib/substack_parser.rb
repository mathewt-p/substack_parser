require 'zip'
require 'csv'

class SubstackParser
  attr_reader :file_path

  def initialize(file_path)
    @file_path = file_path
    validate_zip
  end

  def mailing_list
    raise "email_list could not be found" if email_list_file.nil?
    parse_csv(email_list_file.name)
  end

  def post_list
    posts = parse_csv('posts.csv')
    posts.map do |post|
      post_id = post["post_id"]
      post["post_id"] = post_id.to_i
      post.merge(post_content(post_id))
    end
  end

  def get_read_list_for_post(post_id)
    parse_csv("posts/#{post_id}.opens.csv")
  end

  def get_emails_sent_list_for_post(post_id)
    parse_csv("posts/#{post_id}.delivers.csv")
  end

  def read_list
    grouped_post_details('posts/*.opens.csv')
  end

  def emails_sent_list
    grouped_post_details('posts/*.delivers.csv')
  end

  private

  def unzip_file
    @unzip_file ||= Zip::File.open(file_path)
  end

  def email_list_file
    unzip_file.select{|tt| tt.name.start_with? "email_list"}.first
  end

  def parse_csv(filename)
    content = get_zipped_file_content(filename)
    CSV.parse(content, headers: true).map(&:to_h)
  end

  def post_content(post_id)
    content = get_zipped_file_content("posts/#{post_id}.html")
    { "content" => content }
  end

  def get_zipped_file_content(filename)
    entry = unzip_file.glob(filename).first
    begin
      entry.get_input_stream.read
    rescue NoMethodError
      raise "The file could not be found or accessed."
    end
  end

  def grouped_post_details(path)
    unzip_file.glob(path).flat_map do |file|
      content = file.get_input_stream.read
      CSV.parse(content, headers: true).map(&:to_h)
    end
  end

  def validate_zip
    raise "File is not a zip" unless file_path.end_with?('.zip')
    raise "File not found" unless File.exist?(file_path)
  end
end
