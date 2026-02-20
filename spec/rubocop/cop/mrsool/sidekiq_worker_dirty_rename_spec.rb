# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Mrsool::SidekiqWorkerDirtyRename, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  it 'does not register an offense when worker class name matches path' do
    expect_no_offenses(<<~RUBY, 'app/workers/orders/expire_worker.rb')
      # frozen_string_literal: true

      module Orders
        class ExpireWorker
          include Sidekiq::Worker
          def perform; end
        end
      end
    RUBY
  end

  it 'does not register an offense for top-level worker matching path' do
    expect_no_offenses(<<~RUBY, 'app/workers/notification_worker.rb')
      # frozen_string_literal: true

      class NotificationWorker
        include Sidekiq::Worker
        def perform; end
      end
    RUBY
  end

  it 'registers an offense when worker class name does not match path' do
    expect_offense(<<~RUBY, 'app/workers/orders/expire_worker.rb')
      # frozen_string_literal: true

      module Orders
        class ExpireOrderWorker
        ^^^^^^^^^^^^^^^^^^^^^ Do not change Sidekiq worker names. Expected `Orders::ExpireWorker` (from path) but found `Orders::ExpireOrderWorker`. Keep the worker name the same.
          include Sidekiq::Worker
          def perform; end
        end
      end
    RUBY
  end

  it 'registers an offense when top-level worker class does not match path' do
    expect_offense(<<~RUBY, 'app/workers/sms_worker.rb')
      # frozen_string_literal: true

      class SmsNotificationWorker
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not change Sidekiq worker names. Expected `SmsWorker` (from path) but found `SmsNotificationWorker`. Keep the worker name the same.
        include Sidekiq::Worker
        def perform; end
      end
    RUBY
  end

  it 'registers an offense when current file was added and a worker in same dir was deleted (rename)' do
    allow_any_instance_of(described_class).to receive(:worker_diff_vs_merge_target)
      .and_return(
        { added: ['app/workers/notification_worker.rb'], deleted: ['app/workers/sms_worker.rb'] }
      )

    expect_offense(<<~RUBY, 'app/workers/notification_worker.rb')
      # frozen_string_literal: true

      class NotificationWorker
      ^^^^^^^^^^^^^^^^^^^^^^ Sidekiq worker rename detected vs merge target: you added this file and deleted app/workers/sms_worker.rb. Keep the deleted file(s) so both class names are loadable (e.g. OldWorker = NewWorker in the old file). See https://github.com/sidekiq/sidekiq/wiki/FAQ#how-do-i-safely-rename-a-job-class
        include Sidekiq::Worker
        def perform; end
      end
    RUBY
  end

  it 'does not register a rename offense when no worker was deleted in same dir' do
    allow_any_instance_of(described_class).to receive(:worker_diff_vs_merge_target)
      .and_return({ added: ['app/workers/notification_worker.rb'], deleted: [] })

    expect_no_offenses(<<~RUBY, 'app/workers/notification_worker.rb')
      # frozen_string_literal: true

      class NotificationWorker
        include Sidekiq::Worker
        def perform; end
      end
    RUBY
  end

  it 'does not register a rename offense when diff is unavailable (no merge target / no git)' do
    allow_any_instance_of(described_class).to receive(:worker_diff_vs_merge_target).and_return(nil)

    expect_no_offenses(<<~RUBY, 'app/workers/notification_worker.rb')
      # frozen_string_literal: true

      class NotificationWorker
        include Sidekiq::Worker
        def perform; end
      end
    RUBY
  end

  it 'does not register an offense for non-worker files' do
    expect_no_offenses(<<~RUBY, 'app/workers/orders/expire_worker.rb')
      # frozen_string_literal: true

      module Orders
        class ExpireOrderWorker
          def perform; end
        end
      end
    RUBY
  end

  it 'does not register an offense for files outside app/workers' do
    expect_no_offenses(<<~RUBY, 'app/services/notifier.rb')
      class Notifier
        include SomethingElse
      end
    RUBY
  end
end
