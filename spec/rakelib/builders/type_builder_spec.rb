# frozen_string_literal: true

require_relative '../../../rakelib/builders/type_builder'
require_relative '../../../rakelib/builders/type_dependencies'

RSpec.describe Builders::TypeBuilder do
  subject(:builder) do
    described_class.new(
      type_name,
      attributes,
      templates_dir: templates_dir,
      dependencies: dependencies
    )
  end

  let(:templates_dir) { File.expand_path('../../../rakelib/templates', __dir__) }
  let(:type_name) { 'RichText' }
  let(:attributes) { { type: members } }
  let(:members) { %w[string array:RichText RichTextBold] }
  let(:types) do
    {
      'RichText' => { type: members },
      'RichTextBold' => {
        type: { type: 'string', required: true, required_value: 'bold' },
        text: { type: 'string', required: true }
      }
    }
  end
  let(:dependencies) { Builders::TypeDependencies.new(types) }

  describe '#build for empty (sum) types' do
    subject(:output) { builder.build }

    it 'maps string members to Types::String first' do
      expect(output).to match(/RichText = \(\s*Types::String\s*\|/m)
    end

    it 'maps array:Name members to deferred Array.of' do
      expect(output).to include('Types::Array.of(Types.deferred(:RichText))')
    end

    it 'keeps struct member names as-is' do
      expect(output).to include("RichTextBold\n")
    end

    it 'emits a valid empty-type module shell' do
      expect(output).to match(/module Telegram\b.*\bRichText = \(.*\)/m)
    end

    context 'with only struct members' do
      let(:members) { %w[ChatMemberOwner ChatMemberAdministrator] }

      it 'joins struct members without string/array wrappers' do
        expect(output).to match(
          /ChatMemberOwner\s*\|\s*ChatMemberAdministrator\n/
        ).and(satisfy { |body| !body.include?('Types::String') && !body.include?('Types::Array') })
      end
    end
  end

  describe '#build for optional booleans' do
    subject(:output) { builder.build }

    let(:type_name) { 'EphemeralMessageParameters' }
    let(:attributes) do
      {
        replace_callback_query_message: {
          type: 'boolean'
        }
      }
    end
    let(:types) { { type_name => attributes } }

    it 'does not add a constraint or default' do
      expect(output).to include(
        'attribute? :replace_callback_query_message, Types::Bool'
      )
    end
  end

  describe '#build for formatted numeric constraints' do
    subject(:output) { builder.build }

    let(:type_name) { 'SuggestedPostPrice' }
    let(:attributes) do
      {
        amount: {
          type: 'integer',
          min_size: 5,
          max_size: 100_000
        }
      }
    end
    let(:types) { { type_name => attributes } }

    it 'uses separators in large numeric literals' do
      expect(output).to include('max_size: 100_000')
    end
  end

  describe '#build for max-only constraints' do
    subject(:output) { builder.build }

    let(:type_name) { 'Game' }
    let(:attributes) do
      {
        text: {
          type: 'string',
          max_size: 4_096
        }
      }
    end
    let(:types) { { type_name => attributes } }

    it 'emits a max_size predicate without a min_size prefix' do
      expect(output).to include('Types::String.constrained(max_size: 4_096)')
    end
  end

  describe '#build for long union attributes' do
    subject(:output) { builder.build }

    let(:type_name) { 'InputRichMessageMedia' }
    let(:attributes) do
      {
        media: {
          type: %w[
            InputMediaAnimation
            InputMediaAudio
            InputMediaDocument
            InputMediaPhoto
            InputMediaVideo
            InputMediaVoiceNote
          ]
        }
      }
    end
    let(:types) { { type_name => attributes } }

    it 'wraps long union types across lines' do
      expect(output).to match(/attribute\? :media,\n\s+InputMediaAnimation.*\n\s+InputMediaVoiceNote/)
    end
  end
end
