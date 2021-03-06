require 'spec_helper'

describe PgPower::Migration::CommandRecorder::ExtensionMethods do
  class CommandRecorderStub
    include ::PgPower::Migration::CommandRecorder::ExtensionMethods
  end

  let(:command_recorder_stub) { CommandRecorderStub.new }

  [:create_extension, :drop_extension].each do |method_name|
    it ".#{method_name}" do
      command_recorder_stub.should_receive(:record).with(method_name, [:foo, :bar])
      command_recorder_stub.send(method_name, :foo, :bar)
    end
  end

  it ".invert_create_extension" do
    expect(command_recorder_stub.invert_create_extension([:foo, :bar])).
      to eq([:drop_extension, [:foo]])
  end

  it ".invert_drop_extension" do
    expect(command_recorder_stub.invert_drop_extension([:foo, :bar])).
      to eq([:create_extension, [:foo]])
  end
end
