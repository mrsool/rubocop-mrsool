# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Mrsool::LetsNot, :config do
  let(:config) { RuboCop::Config.new }

  it "registers an offense when using inline `let`" do
    expect_offense(<<~RUBY)
      let(:foo) { 'bar' }
      ^^^^^^^^^^^^^^^^^^^ Do not use `let` for test setup. https://thoughtbot.com/blog/lets-not
    RUBY
  end

  it "registers an offense when using `let` with multiline block" do
    expect_offense(<<~RUBY)
      let(:foo) do
      ^^^^^^^^^^^^ Do not use `let` for test setup. https://thoughtbot.com/blog/lets-not
        'bar'
      end
    RUBY
  end

  it "registers an offense when using string" do
    expect_offense(<<~RUBY)
      let('foo') { 'bar' }
      ^^^^^^^^^^^^^^^^^^^^ Do not use `let` for test setup. https://thoughtbot.com/blog/lets-not
    RUBY
  end
end
