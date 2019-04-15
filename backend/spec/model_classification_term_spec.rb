require 'spec_helper'
require_relative 'spec_slugs_helper'

describe 'Classification models' do

  describe "slug tests" do
    before (:all) do
      AppConfig[:use_human_readable_URLs] = true
    end

    describe "slug autogen enabled" do
      it "autogenerates a slug via title when configured to generate by name" do
        AppConfig[:auto_generate_slugs_with_id] = false

        classification_term = ClassificationTerm.create_from_json(build(:json_classification_term, :is_slug_auto => true, :title => rand(100000).to_s))

        expected_slug = clean_slug(classification_term[:title])

        expect(classification_term[:slug]).to eq(expected_slug)
      end

      it "autogenerates a slug via identifier when configured to generate by id" do
        AppConfig[:auto_generate_slugs_with_id] = true

        classification_term = ClassificationTerm.create_from_json(build(:json_classification_term, :is_slug_auto => true))

        expected_slug = clean_slug(classification_term[:identifier])

        expect(classification_term[:slug]).to eq(expected_slug)
      end

      it "turns off autogen if slug is blank" do
        classification_term = ClassificationTerm.create_from_json(build(:json_classification_term, :is_slug_auto => true))
        classification_term.update(:slug => "")

        expect(classification_term[:is_slug_auto]).to eq(0)
      end

      it "cleans slug when autogenerating by name" do
        AppConfig[:auto_generate_slugs_with_id] = false

        classification_term = ClassificationTerm.create_from_json(build(:json_classification_term, :is_slug_auto => true, :title => "Foo Bar Baz&&&&"))

        expect(classification_term[:slug]).to eq("foo_bar_baz")
      end

      it "dedupes slug when autogenerating by name" do
        AppConfig[:auto_generate_slugs_with_id] = false

        classification_term1 = ClassificationTerm.create_from_json(build(:json_classification_term, :is_slug_auto => true, :title => "foo"))
        classification_term2 = ClassificationTerm.create_from_json(build(:json_classification_term, :is_slug_auto => true, :title => "foo"))

        expect(classification_term1[:slug]).to eq("foo")
        expect(classification_term2[:slug]).to eq("foo_1")
      end

      it "cleans slug when autogenerating by id" do
        AppConfig[:auto_generate_slugs_with_id] = true

        classification_term = ClassificationTerm.create_from_json(build(:json_classification_term, :is_slug_auto => true, :identifier => "Foo Bar Baz&&&&"))

        expect(classification_term[:slug]).to eq("foo_bar_baz")
      end

      it "dedupes slug when autogenerating by id" do
        AppConfig[:auto_generate_slugs_with_id] = true

        classification_term1 = ClassificationTerm.create_from_json(build(:json_classification_term, :is_slug_auto => true, :identifier => "foo"))
        classification_term2 = ClassificationTerm.create_from_json(build(:json_classification_term, :is_slug_auto => true, :identifier => "foo#"))

        expect(classification_term1[:slug]).to eq("foo")
        expect(classification_term2[:slug]).to eq("foo_1")
      end
    end

    describe "slug autogen disabled" do
      it "slug does not change when config set to autogen by title and title updated" do
        AppConfig[:auto_generate_slugs_with_id] = false

        classification_term = ClassificationTerm.create_from_json(build(:json_classification_term, :is_slug_auto => false, :slug => "foo"))

        classification_term.update(:title => rand(100000000))

        expect(classification_term[:slug]).to eq("foo")
      end

      it "slug does not change when config set to autogen by id and id updated" do
        AppConfig[:auto_generate_slugs_with_id] = false

        classification_term = ClassificationTerm.create_from_json(build(:json_classification_term, :is_slug_auto => false, :slug => "foo"))

        classification_term.update(:identifier => rand(100000000))

        expect(classification_term[:slug]).to eq("foo")
      end
    end

    describe "manual slugs" do
      it "cleans manual slugs" do
        classification_term = ClassificationTerm.create_from_json(build(:json_classification_term, :is_slug_auto => false))
        classification_term.update(:slug => "Foo Bar Baz ###")

        expect(classification_term[:slug]).to eq("foo_bar_baz")
      end

      it "dedupes manual slugs" do
        classification_term1 = ClassificationTerm.create_from_json(build(:json_classification_term, :is_slug_auto => false, :slug => "foo"))
        classification_term2 = ClassificationTerm.create_from_json(build(:json_classification_term, :is_slug_auto => false))

        classification_term2.update(:slug => "foo")

        expect(classification_term1[:slug]).to eq("foo")
        expect(classification_term2[:slug]).to eq("foo_1")
      end
    end
  end
end
