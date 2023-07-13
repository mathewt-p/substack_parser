require "spec_helper"

RSpec.describe SubstackParser do
  let(:file_path) { "#{__dir__}/fixtures/sample_files.zip" }
  subject { SubstackParser.new(file_path) }

  describe "Zip file parsing" do
    it "parses the Zip file" do
      unziped_files = subject.send(:unzip_file)
      expect(unziped_files.count).to eq(15)
    end
  end

  describe "Mailing list CSV parsing" do
    it "parses the Mailing list CSV" do
      mailing_list = subject.mailing_list
      expect(mailing_list.count).to eq(11)
      expect(mailing_list.first.keys).to eq(["email", "active_subscription", "expiry", "plan", "email_disabled", "digest_enabled", "created_at"])
    end
  end

  describe "Post list CSV parsing" do
    it "parses the Post list CSV" do
      post_list = subject.post_list
      expect(post_list.count).to eq(4)
      expect(post_list.first.keys).to eq(["post_id", "post_date", "is_published", "email_sent_at", "inbox_sent_at", "type", "audience", "title", "subtitle", "podcast_url", "content"])
      expect(post_list.first["post_id"]).to eq(1)
    end
  end

  describe "Post Read list parsing" do
    let(:read_list) { subject.read_list }
    let(:post_list) { subject.post_list.map { |post| post["post_id"].to_i } }

    it "parses the Post Read list for all posts" do
      expect(post_list).to include(*read_list.map { |post| post["post_id"].to_i }.uniq)
      expect(read_list.first.keys).to eq(["post_id", "timestamp", "email", "post_type", "post_audience", "active_subscription", "country", "city", "region", "device_type", "client_os", "client_type", "user_agent"])
    end
  end

  describe "Post Emails sent list parsing" do
    let(:emails_sent_list) { subject.emails_sent_list }
    let(:post_list) { subject.post_list.map { |post| post["post_id"].to_i } }

    it "parses the Post Emails sent list for all posts" do
      expect(post_list).to include(*emails_sent_list.map { |post| post["post_id"].to_i }.uniq)
      expect(emails_sent_list.first.keys).to eq(["post_id", "timestamp", "email", "post_type", "post_audience", "active_subscription"])
    end
  end

  describe "Individual Post Read list parsing" do
    let(:read_list) { subject.get_read_list_for_post(2) }

    it "parses the Read list for a post" do
      expect(read_list.count).to eq(5)
      expect(read_list.first.keys).to eq(["post_id", "timestamp", "email", "post_type", "post_audience", "active_subscription", "country", "city", "region", "device_type", "client_os", "client_type", "user_agent"])
      expect(read_list.map { |post| post["post_id"] }.uniq).to eq(["2"])
    end
  end

  describe "Individual Post Emails sent list parsing" do
    let(:emails_sent_list) { subject.get_emails_sent_list_for_post(3) }

    it "parses the Emails sent list for a post" do
      expect(emails_sent_list.count).to eq(5)
      expect(emails_sent_list.first.keys).to eq(["post_id", "timestamp", "email", "post_type", "post_audience", "active_subscription"])
      expect(emails_sent_list.map { |post| post["post_id"] }.uniq).to eq(["3"])
    end
  end

  describe "Expect to raise error" do
    describe "invalid Zip file" do
      let!(:file_path) { "#{__dir__}/fixtures/sample_files1.csv" }
      it "raises error when file is not a zip" do
        expect { subject }.to raise_error("File is not a zip")
      end
    end

    describe "Missing Zip file" do
      let!(:file_path) { "#{__dir__}/fixtures/sample_files1.zip" }
      it "raises error when file is not a zip" do
        expect { subject }.to raise_error("File not found")
      end
    end

    describe "Invalid/ missing CSv file" do
      it "raises error file not found" do
        expect { subject.get_read_list_for_post(5) }.to raise_error("The file could not be found or accessed.")
      end
    end
  end
end
