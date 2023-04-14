# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Mrsool::Paperclip, :config do
  let(:config) { RuboCop::Config.new }

  it "registers an offense when using `has_attached_file`" do
    expect_offense(<<~RUBY)
      has_attached_file :foo, path: ""
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{described_class::MSG}
    RUBY
  end
end
