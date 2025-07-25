# frozen_string_literal: true

# Author::    Sergio Fierens (Implementation only, Cendrowska is
# the creator of the algorithm)
# License::   MPL 1.1
# Project::   ai4r
# Url::       https://github.com/SergioFierens/ai4r
#
# You can redistribute it and/or modify it under the terms of
# the Mozilla Public License version 1.1  as published by the
# Mozilla Foundation at http://www.mozilla.org/MPL/MPL-1.1.txt
#
# J. Cendrowska (1987). PRISM: An algorithm for inducing modular rules.
# International Journal of Man-Machine Studies. 27(4):349-370.

require_relative '../data/data_set'
require_relative '../classifiers/classifier'

module Ai4r
  module Classifiers
    # = Introduction
    # This is an implementation of the PRISM algorithm (Cendrowska, 1987)
    # Given a set of preclassified examples, it builds a set of rules
    # to predict the class of other instaces.
    #
    # J. Cendrowska (1987). PRISM: An algorithm for inducing modular rules.
    # International Journal of Man-Machine Studies. 27(4):349-370.
    class Prism < Classifier
      attr_reader :data_set, :rules, :majority_class

      parameters_info(
        fallback_class: 'Default class returned when no rule matches.',
        bin_count: 'Number of bins used to discretize numeric attributes.',
        default_class: 'Return this value when no rule matches.',
        tie_break: 'Strategy when multiple conditions have equal ratios.'
      )

      def initialize
        super()
        @fallback_class = nil
        @bin_count = 10
        @attr_bins = {}

        @default_class = nil
        @tie_break = :first
        @bin_count = 10
        @attr_bins = {}
      end

      # Build a new Prism classifier. You must provide a DataSet instance
      # as parameter. The last attribute of each item is considered as
      # the item class.
      # @param data_set [Object]
      # @return [Object]
      def build(data_set)
        data_set.check_not_empty
        @data_set = data_set

        freqs = Hash.new(0)
        @data_set.data_items.each { |item| freqs[item.last] += 1 }
        @majority_class = freqs.max_by { |_, v| v }&.first
        @fallback_class = @default_class if @default_class
        @fallback_class = @majority_class if @fallback_class.nil?

        domains = @data_set.build_domains
        @attr_bins = {}
        domains[0...-1].each_with_index do |domain, i|
          @attr_bins[@data_set.data_labels[i]] = discretize_range(domain, @bin_count) if domain.is_a?(Array) && domain.length == 2 && domain.all? { |v| v.is_a? Numeric }
        end
        instances = @data_set.data_items.collect { |data| data }
        @rules = []
        domains.last.each do |class_value|
          while class_value?(instances, class_value)
            rule = build_rule(class_value, instances)
            @rules << rule
            instances = instances.reject { |data| matches_conditions(data, rule[:conditions]) }
          end
        end
        self
      end

      # You can evaluate new data, predicting its class.
      # e.g.
      #   classifier.eval(['New York',  '<30', 'F'])  # => 'Y'
      # @param instace [Object]
      # @return [Object]
      def eval(instace)
        @rules.each do |rule|
          return rule[:class_value] if matches_conditions(instace, rule[:conditions])
        end
        @default_class || @fallback_class
      end

      # This method returns the generated rules in ruby code.
      # e.g.
      #
      #   classifier.get_rules
      #     # => if age_range == '<30' then marketing_target = 'Y'
      #    elsif age_range == '>80' then marketing_target = 'Y'
      #    elsif city == 'Chicago' and age_range == '[30-50)' then marketing_target = 'Y'
      #    else marketing_target = 'N'
      #    end
      #
      # It is a nice way to inspect induction results, and also to execute them:
      #        age_range = '[30-50)'
      #        city = 'New York'
      #        eval(classifier.get_rules)
      #        puts marketing_target
      #         'Y'
      # @return [Object]
      def get_rules
        out = "if #{join_terms(@rules.first)} then #{then_clause(@rules.first)}"
        @rules[1...-1].each do |rule|
          out += "\nelsif #{join_terms(rule)} then #{then_clause(rule)}"
        end
        out += "\nelse #{then_clause(@rules.last)}" if @rules.size > 1
        out += "\nend"
        out
      end

      protected

      # @param data [Object]
      # @param attr [Object]
      # @return [Object]
      def get_attr_value(data, attr)
        data[@data_set.get_index(attr)]
      end

      # @param instances [Object]
      # @param class_value [Object]
      # @return [Object]
      def class_value?(instances, class_value)
        instances.any? { |data| data.last == class_value }
      end

      # @param instances [Object]
      # @param rule [Object]
      # @return [Object]
      def perfect?(instances, rule)
        class_value = rule[:class_value]
        instances.each do |data|
          return false if (data.last != class_value) && matches_conditions(data, rule[:conditions])
        end
        true
      end

      # @param data [Object]
      # @param conditions [Object]
      # @return [Object]
      def matches_conditions(data, conditions)
        conditions.each_pair do |attr_label, attr_value|
          value = get_attr_value(data, attr_label)
          if attr_value.is_a?(Range)
            return false unless attr_value.include?(value)
          else
            return false unless value == attr_value
          end
        end
        true
      end

      # @param class_value [Object]
      # @param instances [Object]
      # @return [Object]
      def build_rule(class_value, instances)
        rule = { class_value: class_value, conditions: {} }
        rule_instances = instances.collect { |data| data }
        attributes = @data_set.data_labels[0...-1].collect { |label| label }
        until perfect?(instances, rule) || attributes.empty?
          freq_table = build_freq_table(rule_instances, attributes, class_value)
          condition = get_condition(freq_table)
          rule[:conditions].merge!(condition)
          attributes.delete(condition.keys.first)
          rule_instances = rule_instances.select do |data|
            matches_conditions(data, condition)
          end
        end
        rule
      end

      # Returns a structure with the folloring format:
      # => {attr1_label => { :attr1_value1 => [p, t], attr1_value2 => [p, t], ... },
      #     attr2_label => { :attr2_value1 => [p, t], attr2_value2 => [p, t], ... },
      #     ...
      #     }
      # where p is the number of instances classified as class_value
      # with that attribute value, and t is the total number of instances with
      # that attribute value
      # @param rule_instances [Object]
      # @param attributes [Object]
      # @param class_value [Object]
      # @return [Object]
      def build_freq_table(rule_instances, attributes, class_value)
        freq_table = {}
        rule_instances.each do |data|
          attributes.each do |attr_label|
            attr_freqs = freq_table[attr_label] || Hash.new([0, 0])
            value = get_attr_value(data, attr_label)
            if (bins = @attr_bins[attr_label])
              value = bins.find { |b| b.include?(value) }
            end
            pt = attr_freqs[value]
            pt = [data.last == class_value ? pt[0] + 1 : pt[0], pt[1] + 1]
            attr_freqs[value] = pt
            freq_table[attr_label] = attr_freqs
          end
        end
        freq_table
      end

      # returns a single conditional term: {attrN_label => attrN_valueM}
      # selecting the attribute with higher pt ratio
      # (occurrences of attribute value classified as class_value /
      #  occurrences of attribute value)
      # @param freq_table [Object]
      # @return [Object]
      def get_condition(freq_table)
        best_pt = [0, 0]
        condition = nil
        freq_table.each do |attr_label, attr_freqs|
          attr_freqs.each do |attr_value, pt|
            if better_pt(pt, best_pt)
              condition = { attr_label => attr_value }
              best_pt = pt
            end
          end
        end
        condition
      end

      # pt = [p, t]
      # p = occurrences of attribute value with instance classified as class_value
      # t = occurrences of attribute value
      # a pt is better if:
      #   1- its ratio is higher
      #   2- its ratio is equal, and has a higher p
      # @param pt [Object]
      # @param best_pt [Object]
      # @return [Object]
      def better_pt(pt, best_pt)
        return false if pt[1].zero?
        return true if best_pt[1].zero?

        a = pt[0] * best_pt[1]
        b = best_pt[0] * pt[1]
        return true if a > b || (a == b && pt[0] > best_pt[0])
        return true if a == b && pt[0] == best_pt[0] && @tie_break == :last

        false
      end

      # @param range [Object]
      # @param bins [Object]
      # @return [Object]
      def discretize_range(range, bins)
        min, max = range
        step = (max - min).to_f / bins
        ranges = []
        bins.times do |i|
          low = min + (i * step)
          high = i == bins - 1 ? max : min + ((i + 1) * step)
          ranges << (i == bins - 1 ? (low..high) : (low...high))
        end
        ranges
      end

      # @param rule [Object]
      # @return [Object]
      def join_terms(rule)
        terms = rule[:conditions].map do |attr_label, attr_value|
          if attr_value.is_a?(Range)
            "(#{attr_value}).include?(#{attr_label})"
          else
            "#{attr_label} == '#{attr_value}'"
          end
        end
        terms.join(' and ').to_s
      end

      # @param rule [Object]
      # @return [Object]
      def then_clause(rule)
        "#{@data_set.category_label} = '#{rule[:class_value]}'"
      end
    end
  end
end
