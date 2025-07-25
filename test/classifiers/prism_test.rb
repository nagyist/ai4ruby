# frozen_string_literal: true

require_relative '../test_helper'
require 'ai4r/classifiers/prism'
require 'yaml'

class PrismTest < Minitest::Test
  include Ai4r::Classifiers
  include Ai4r::Data

  fixture = YAML.load_file(File.expand_path('../fixtures/marketing_target_age_range.yml', __dir__))

  DATA_EXAMPLES = fixture['data_items']
  DATA_LABELS   = fixture['data_labels']

  numeric_fixture = YAML.load_file(File.expand_path('../fixtures/prism_numeric_examples.yml',
                                                    __dir__))

  NUMERIC_EXAMPLES = numeric_fixture['data_items']
  NUMERIC_LABELS   = numeric_fixture['data_labels']

  def test_build
    assert_raises(ArgumentError) { Ai4r::Classifiers::Prism.new.build(DataSet.new) }
    classifier = Ai4r::Classifiers::Prism.new.build(DataSet.new(data_items: DATA_EXAMPLES))
    refute_nil(classifier.data_set.data_labels)
    refute_nil(classifier.rules)
    assert_equal('attribute_1', classifier.data_set.data_labels.first)
    assert_equal('class_value', classifier.data_set.category_label)
    classifier = Ai4r::Classifiers::Prism.new.build(DataSet.new(data_items: DATA_EXAMPLES,
                                                                data_labels: DATA_LABELS))
    refute_nil(classifier.data_set.data_labels)
    refute_nil(classifier.rules)
    assert_equal('city', classifier.data_set.data_labels.first)
    assert_equal('marketing_target', classifier.data_set.category_label)
    assert !classifier.rules.empty?
  end

  def test_eval
    classifier = Ai4r::Classifiers::Prism.new.build(DataSet.new(data_items: DATA_EXAMPLES))
    DATA_EXAMPLES.each do |data|
      assert_equal(data.last, classifier.eval(data[0...-1]))
    end
  end

  def test_get_rules
    classifier = Ai4r::Classifiers::Prism.new.build(DataSet.new(data_items: DATA_EXAMPLES,
                                                                data_labels: DATA_LABELS))
    ctx = binding
    ctx.local_variable_set(:marketing_target, nil)
    ctx.local_variable_set(:age_range, nil)
    ctx.local_variable_set(:city, 'Chicago')
    ctx.eval(classifier.get_rules)
    ctx.local_variable_set(:age_range, '<30')
    ctx.eval(classifier.get_rules)
    assert_equal('Y', ctx.local_variable_get(:marketing_target))
    ctx.eval(classifier.get_rules)
    assert_equal('Y', ctx.local_variable_get(:marketing_target))
    ctx.eval(classifier.get_rules)
    assert_equal('Y', ctx.local_variable_get(:marketing_target))
    ctx.local_variable_set(:age_range, '[30-50)')
    ctx.local_variable_set(:city, 'New York')
    ctx.eval(classifier.get_rules)
    assert_equal('N', ctx.local_variable_get(:marketing_target))
    ctx.local_variable_set(:age_range, '[50-80]')
    ctx.eval(classifier.get_rules)
    assert_equal('N', ctx.local_variable_get(:marketing_target))
  end

  def test_matches_conditions
    classifier = Ai4r::Classifiers::Prism.new.build(DataSet.new(data_labels: DATA_LABELS,
                                                                data_items: DATA_EXAMPLES))

    assert classifier.send(:matches_conditions,
                           ['New York', '<30', 'M', 'Y'], { 'age_range' => '<30' })
    assert !classifier.send(:matches_conditions,
                            ['New York', '<30', 'M', 'Y'], { 'age_range' => '[50-80]' })
  end

  def test_default_class
    classifier = Ai4r::Classifiers::Prism.new.set_parameters(default_class: 'Z').build(
      DataSet.new(data_items: DATA_EXAMPLES, data_labels: DATA_LABELS)
    )
    classifier.instance_variable_set(:@rules, [])
    assert_equal('Z', classifier.eval(['Paris', '<30', 'M']))
  end

  def test_tie_break
    tie_examples = [
      %w[A X foo Y],
      %w[B X foo Y],
      %w[A Y foo Y],
      %w[B Y foo N]
    ]
    labels = %w[att0 att1 att2 class]
    ds = DataSet.new(data_items: tie_examples, data_labels: labels)
    c_first = Ai4r::Classifiers::Prism.new.build(ds)
    assert_equal({ 'att0' => 'A' }, c_first.rules.first[:conditions])
    c_last = Ai4r::Classifiers::Prism.new.set_parameters(tie_break: :last).build(ds)
    assert_equal({ 'att1' => 'X' }, c_last.rules.first[:conditions])
  end

  def test_fallback_class
    classifier = Ai4r::Classifiers::Prism.new.build(DataSet.new(data_items: DATA_EXAMPLES))
    classifier.rules.pop
    assert_equal(classifier.majority_class,
                 classifier.eval(['New York', '[50-80]', 'M']))

    classifier = Ai4r::Classifiers::Prism.new.set_parameters(fallback_class: 'Z').build(
      DataSet.new(data_items: DATA_EXAMPLES)
    )
    classifier.rules.pop
    assert_equal('Z', classifier.eval(['New York', '[50-80]', 'M']))
  end

  def test_rules_have_unique_attributes
    classifier = Ai4r::Classifiers::Prism.new.build(DataSet.new(data_labels: DATA_LABELS,
                                                                data_items: DATA_EXAMPLES))
    classifier.rules.each do |rule|
      keys = rule[:conditions].keys
      assert_equal keys.uniq, keys
    end
  end

  def test_build_with_single_attribute
    examples = [
      %w[red apple],
      %w[red berry],
      %w[blue berry]
    ]
    labels = %w[color kind]
    classifier = Ai4r::Classifiers::Prism.new.build(DataSet.new(data_items: examples,
                                                                data_labels: labels))
    refute_nil classifier.rules
    assert !classifier.rules.empty?
    classifier.rules.each do |rule|
      assert rule[:conditions].keys.size <= 1
    end
  end

  def test_numeric_data
    classifier = Ai4r::Classifiers::Prism.new.build(DataSet.new(
                                                      data_items: NUMERIC_EXAMPLES,
                                                      data_labels: NUMERIC_LABELS
                                                    ))
    assert(classifier.rules.any? { |r| r[:conditions].values.any? { |v| v.is_a?(Range) } })
    assert_equal('Y', classifier.eval(['New York', 20, 'M']))
    assert_equal('N', classifier.eval(['Chicago', 55, 'M']))
  end
end
