# frozen_string_literal: true

require 'nokogiri'
require_relative '../../../rakelib/parsers/types_parser'

RSpec.describe Parsers::TypesParser do
  subject(:parser) { described_class.new }

  describe '#parse_union_type' do
    def parse_union(description_html, list_items, type_name = 'RichText')
      description = Nokogiri::HTML.fragment(description_html).children.find(&:element?)
      ul_html = list_items.map { |name| %(<li><a href="##{name}">#{name}</a></li>) }.join
      ul = Nokogiri::HTML.fragment("<ul>#{ul_html}</ul>").at('ul')

      parser.send(:parse_union_type, ul, description, type_name)
    end

    it 'collects linked struct members from the union list' do
      result = parse_union('<p>This object represents something.</p>', %w[RichTextBold RichTextItalic])

      expect(result).to eq('type' => %w[RichTextBold RichTextItalic])
    end

    it 'prepends string when prose mentions plain text strings' do
      result = parse_union(
        '<p>This object represents rich text. String for plain text, or one of:</p>',
        %w[RichTextBold]
      )

      expect(result['type']).to eq(%w[string RichTextBold])
    end

    it 'prepends array:TypeName when prose mentions an Array of the type' do
      result = parse_union(
        '<p>This object represents rich text as an Array of RichText, or one of:</p>',
        %w[RichTextBold]
      )

      expect(result['type']).to eq(%w[array:RichText RichTextBold])
    end

    it 'keeps string before array when both are described' do
      result = parse_union(
        '<p>String for plain text, an Array of RichText for sequences, or one of:</p>',
        %w[RichTextBold RichTextItalic]
      )

      expect(result['type']).to eq(%w[string array:RichText RichTextBold RichTextItalic])
    end

    it 'deduplicates members' do
      result = parse_union(
        '<p>String for plain text or one of:</p>',
        %w[string RichTextBold]
      )

      # "string" from prose plus a hypothetical linked "string" collapse via uniq
      expect(result['type']).to eq(%w[string RichTextBold])
    end
  end
end
