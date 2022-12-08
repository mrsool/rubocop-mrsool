# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Mrsool::OrderBuyerId, :config do
  let(:config) { RuboCop::Config.new }

  context "with order.iBuyerId and user_id" do
    it "matches ==" do
      expect_offense(<<~RUBY)
        order.iBuyerId == user_id
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Use `buyer?(user_or_id)`
      RUBY

      expect_correction(<<~RUBY)
        order.buyer?(user_id)
      RUBY
    end

    it "matches !=" do
      expect_offense(<<~RUBY)
        order.iBuyerId != user_id
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Use `buyer?(user_or_id)`
      RUBY

      expect_correction(<<~RUBY)
        !order.buyer?(user_id)
      RUBY
    end

    it "matches eql?" do
      expect_offense(<<~RUBY)
        order.iBuyerId.eql?(user_id)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `buyer?(user_or_id)`
      RUBY

      expect_correction(<<~RUBY)
        order.buyer?(user_id)
      RUBY
    end
  end

  context "with order.iBuyerId and user.id" do
    it "matches ==" do
      expect_offense(<<~RUBY)
        order.iBuyerId == user.id
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Use `buyer?(user_or_id)`
      RUBY

      expect_correction(<<~RUBY)
        order.buyer?(user)
      RUBY
    end

    it "matches !=" do
      expect_offense(<<~RUBY)
        order.iBuyerId != user.id
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Use `buyer?(user_or_id)`
      RUBY

      expect_correction(<<~RUBY)
        !order.buyer?(user)
      RUBY
    end

    it "matches eql?" do
      expect_offense(<<~RUBY)
        order.iBuyerId.eql?(user.id)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `buyer?(user_or_id)`
      RUBY

      expect_correction(<<~RUBY)
        order.buyer?(user)
      RUBY
    end
  end

  context "with user_id and order.iBuyerId" do
    it "matches ==" do
      expect_offense(<<~RUBY)
        user_id == order.iBuyerId
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Use `buyer?(user_or_id)`
      RUBY

      expect_correction(<<~RUBY)
        order.buyer?(user_id)
      RUBY
    end

    it "matches !=" do
      expect_offense(<<~RUBY)
        user_id != order.iBuyerId
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Use `buyer?(user_or_id)`
      RUBY

      expect_correction(<<~RUBY)
        !order.buyer?(user_id)
      RUBY
    end

    it "matches eql?" do
      expect_offense(<<~RUBY)
        user_id.eql?(order.iBuyerId)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `buyer?(user_or_id)`
      RUBY

      expect_correction(<<~RUBY)
        order.buyer?(user_id)
      RUBY
    end
  end

  context "with user.id and order.iBuyerId" do
    it "matches ==" do
      expect_offense(<<~RUBY)
        user.id == order.iBuyerId
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Use `buyer?(user_or_id)`
      RUBY

      expect_correction(<<~RUBY)
        order.buyer?(user)
      RUBY
    end

    it "matches !=" do
      expect_offense(<<~RUBY)
        user.id != order.iBuyerId
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Use `buyer?(user_or_id)`
      RUBY

      expect_correction(<<~RUBY)
        !order.buyer?(user)
      RUBY
    end

    it "matches eql?" do
      expect_offense(<<~RUBY)
        user.id.eql?(order.iBuyerId)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `buyer?(user_or_id)`
      RUBY

      expect_correction(<<~RUBY)
        order.buyer?(user)
      RUBY
    end
  end
end
