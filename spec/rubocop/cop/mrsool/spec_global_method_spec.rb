# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Mrsool::SpecGlobalMethod, :config do
  let(:config) { RuboCop::Config.new }

  it "registers an offense when a global method is defined below describe block" do
    expect_offense(<<~RUBY)
      RSpec.describe "Something" do
        it "works" do
          help_me
        end
      end

      def help_me
      ^^^^^^^^^^^ #{described_class::MSG}
        # must fail
      end
    RUBY
  end

  it "registers an offense when a global method is defined above describe block" do
    expect_offense(<<~RUBY)
      require "rails_helper"

      def help_me
      ^^^^^^^^^^^ #{described_class::MSG}
        # must fail
      end

      RSpec.describe "Something" do
        it "works" do
          help_me
        end
      end
    RUBY
  end

  it "registers no offense when defining methods inside `describe` block" do
    expect_no_offenses(<<~RUBY)
      RSpec.describe "Something" do
        it "works" do
          help_me
        end

        def help_me
          # all good
        end
      end
    RUBY
  end

  it "registers no offense when defining methods inside a module" do
    expect_no_offenses(<<~RUBY)
      module MyMixin
        def help_me
          # all good
        end
      end
    RUBY
  end

  it "registers no offense when defining methods inside a class" do
    expect_no_offenses(<<~RUBY)
      class MyClass
        def help_me
          # all good
        end
      end
    RUBY
  end
end
