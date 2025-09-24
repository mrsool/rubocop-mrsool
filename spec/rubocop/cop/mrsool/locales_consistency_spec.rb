# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Mrsool::LocalesConsistency, :config do
  let(:config) { RuboCop::Config.new }
  let(:cop_instance) { described_class.new(config) }

  before do
    # Create temporary locale files for testing
    @temp_dir = Dir.mktmpdir('locale_test')
    @locales_dir = File.join(@temp_dir, 'config', 'locales')
    FileUtils.mkdir_p(@locales_dir)
  end

  after do
    FileUtils.rm_rf(@temp_dir)
  end

  def create_locale_file(path, content)
    full_path = File.join(@temp_dir, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  def run_cop_investigation(yaml_content, path)
    # Create ProcessedSource for the YAML content
    file_path = File.join(@temp_dir, path)
    processed_source = RuboCop::ProcessedSource.new(yaml_content, RUBY_VERSION.to_f, file_path)
    cop_instance.instance_variable_set(:@processed_source, processed_source)
    
    # Run the investigation
    cop_instance.send(:on_new_investigation)
    
    # Get the generated offenses and return clean messages
    offenses = cop_instance.instance_variable_get(:@offenses) || []
    offense_array = offenses.is_a?(Array) ? offenses : [offenses]
    offense_array.map { |offense| offense.message.gsub(@temp_dir + '/', '') }
  end

  it "does not return missing keys if there is no missing key" do
    en_content = <<~YAML
      en:
        hello: "Hello"
    YAML

    ar_content = <<~YAML
      ar:
        hello: "مرحبا"
    YAML

    create_locale_file('config/locales/en.yml', en_content)
    create_locale_file('config/locales/ar.yml', ar_content)

    messages = run_cop_investigation(en_content, 'config/locales/en.yml')
    expect(messages).to be_empty
  end

  it "does not return missing keys if there is no equivalent file" do
    en_content = <<~YAML
      en:
        hello: "Hello"
    YAML

    ar_content = <<~YAML
      ar:
        hello: "مرحبا"
    YAML

    create_locale_file('config/locales/en.yml', en_content)
    create_locale_file('config/locales/test/ar.yml', ar_content) # different path, no equivalent file

    messages = run_cop_investigation(en_content, 'config/locales/en.yml')
    expect(messages).to be_empty
  end

  it "returns missing keys in all supported languages" do
    en_content = <<~YAML
      en:
        hello: "Hello"
        goodbye: "Goodbye"
    YAML

    ar_content = <<~YAML
      ar:
    YAML

    ur_content = <<~YAML
      ur:
    YAML

    bn_content = <<~YAML
      bn:
    YAML

    hi_content = <<~YAML
      hi:
    YAML

    create_locale_file('config/locales/en.yml', en_content)
    create_locale_file('config/locales/ar.yml', ar_content)
    create_locale_file('config/locales/ur.yml', ur_content)
    create_locale_file('config/locales/bn.yml', bn_content)
    create_locale_file('config/locales/hi.yml', hi_content)

    messages = run_cop_investigation(en_content, 'config/locales/en.yml')
    
    # Check that we got the expected number of messages
    expect(messages.size).to eq(2), "Expected 2 messages for 2 missing keys"
    # Check that all expected keys are reported
    expect(messages).to eq(
      [
        'Missing translation key "hello" in locale files: config/locales/ar.yml, config/locales/ur.yml, config/locales/bn.yml, config/locales/hi.yml',
        'Missing translation key "goodbye" in locale files: config/locales/ar.yml, config/locales/ur.yml, config/locales/bn.yml, config/locales/hi.yml'
      ]
    )
  end

  it "returns missing nested keys" do
    en_content = <<~YAML
      en:
        user:
          profile:
            bio: "Bio"
    YAML

    ar_content = <<~YAML
      ar:
    YAML

    create_locale_file('config/locales/en.yml', en_content)
    create_locale_file('config/locales/ar.yml', ar_content)

    messages = run_cop_investigation(en_content, 'config/locales/en.yml')
    expect(messages.size).to eq(1), "Expected 1 message for 1 missing key"
    expect(messages).to eq(
      [
        'Missing translation key "user.profile.bio" in locale files: config/locales/ar.yml'
      ]
    )
  end

  it "handles invalid YAML gracefully [ignores the file if it's invalid]" do
    en_content = <<~YAML
      en:
        hello: [unclosed array
    YAML

    ar_content = <<~YAML
      ar:
    YAML

    create_locale_file('config/locales/en.yml', en_content)
    create_locale_file('config/locales/ar.yml', ar_content)

    messages = run_cop_investigation(en_content, 'config/locales/en.yml')
    expect(messages).to be_empty
  end

  it "handles empty content gracefully" do
    en_content = <<~YAML
      en:
    YAML

    ar_content = <<~YAML
      ar:
        hello: "مرحبا"
    YAML

    create_locale_file('config/locales/en.yml', en_content)
    create_locale_file('config/locales/ar.yml', ar_content)

    messages = run_cop_investigation(en_content, 'config/locales/en.yml')
    expect(messages).to be_empty
  end

  it "handles multi line keys gracefully" do
    en_content = <<~YAML
      en:
        hello: >
          hello
          world
    YAML
    
    ar_content = <<~YAML
      ar:
    YAML

    create_locale_file('config/locales/en.yml', en_content)
    create_locale_file('config/locales/ar.yml', ar_content)

    messages = run_cop_investigation(en_content, 'config/locales/en.yml')
    expect(messages).to eq(['Missing translation key "hello" in locale files: config/locales/ar.yml'])
  end
end
