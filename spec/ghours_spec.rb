require File.dirname(__FILE__) + '/spec_helper.rb'

describe "GHours" do

  it "should throw usage info when no arguments" do
    lambda { GHours.process([]) }.should raise_error(SystemExit)
  end

  describe "when properly invoked" do

    before do
      @config = mock("config")
      GHours::Configuration.should_receive(:new).and_return(@config)
      @connection = mock("connection")
      @connection.stub!(:events)
      GHours::Connection.stub!(:new).and_return(@connection)
    end

    it "should init new configuration when one not found" do
      @config.should_receive(:found?).and_return(false)
      @config.should_receive(:init_new)

      @config.stub!(:credentials)

      GHours.process ["blah"]
    end

    it "should create connection with received credentials" do
      @config.stub!(:found?)
      @config.stub!(:init_new)
      @config.should_receive(:credentials).and_return(["gosia@example.com", "gosia_pass"])
      GHours::Connection.should_receive(:new).with("gosia@example.com", "gosia_pass")

      GHours.process ["blah"]
    end
  end

  describe "Connection" do

    before do
      @gdata = mock("gdata")
      Googlecalendar::GData.should_receive(:new).and_return(@gdata)
    end

    it "should login when initialized" do
      @gdata.should_receive(:login).with("tom@example.com", "secret")
      GHours::Connection.new("tom@example.com", "secret")
    end

    describe "while successfully logged in " do
      before do
        @gdata.stub!(:login)
        @gdata.stub!(:get_calendars)
        @connection = GHours::Connection.new("tom@example.com", "secret")
      end

      it "should throw exception when calendar not found" do
        @gdata.should_receive(:find_calendar).with("calendar_name").and_return(nil)

        lambda { @connection.events("calendar_name") }.should raise_error(GHours::ExitReason)
      end
    end
  end

  describe "Configuration" do
  end

end

