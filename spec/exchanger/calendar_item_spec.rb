require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

SUBJECT = "Test Calendar Item"

describe Exchanger::CalendarItem do
  before do
    @folder = VCR.use_cassette('folder/find_calendar') do
      Exchanger::Folder.find(:calendar)
    end
    @calendar_item = @folder.new_calendar_item(subject: SUBJECT, body: Exchanger::Body.new(text: "Body line 1.\nBody line 2."), start: Time.now, end: Time.now + 30.minutes)
  end

  describe "#save" do
    after do
      if @calendar_item.persisted?
        VCR.use_cassette("calendar_item/save_cleanup") do
          @calendar_item.destroy
        end
      end
    end

    it "should create and update calendar item" do
      VCR.use_cassette("calendar_item/save") do
        prev_items_size = @folder.items.size
        @calendar_item.should be_changed
        @calendar_item.save
        @calendar_item.should_not be_new_record
        @calendar_item.should_not be_changed
        @calendar_item.reload
        @calendar_item.subject.should == SUBJECT
        @folder.items.size.should == prev_items_size + 1
        @calendar_item.subject += " Updated"
        @calendar_item.should be_changed
        @calendar_item.save
        @calendar_item.should_not be_changed
      end
    end
  end

  describe "#file_attachment" do
    after do
      if @calendar_item.persisted?
        VCR.use_cassette("calendar_item/save_file_attachment_cleanup") do
          @calendar_item.destroy
        end
      end
    end

    it "should create and read file attachments" do
      VCR.use_cassette("calendar_item/save_file_attachment") do
        @calendar_item.save

        content = "Test Content"
        file_attachment = @calendar_item.new_file_attachment(name: "test.txt", content_type: "text/plain", content: content)
        file_attachment.save

        @calendar_item.reload  # Pull attachment metadata using GetItem
        @calendar_item.attachments.size.should == 1

        attachment = Exchanger::Attachment.find(@calendar_item.attachments[0].id)  # Pull attachment content using GetAttachment
        attachment.content.should == content

        attachment.destroy
      end
    end
  end
end
