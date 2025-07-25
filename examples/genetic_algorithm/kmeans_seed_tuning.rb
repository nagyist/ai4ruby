#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../../lib/ai4r/genetic_algorithm/genetic_algorithm'
require_relative '../../lib/ai4r/clusterers/k_means'
require_relative '../som/som_data'

##
# Running the genetic search without a fixed random seed leads to
# different SSE results each time, which causes flaky tests in CI.
# Explicitly seed Ruby's random number generator so that the script
# behaves deterministically across runs.
srand 1

# Chromosome used to search for a good random seed for KMeans.
class SeedChromosome < Ai4r::GeneticAlgorithm::ChromosomeBase
  RANGE = (0..10)
  DATA = Ai4r::Data::DataSet.new(data_items: SOM_DATA.first(30))

  def fitness
    return @fitness if @fitness

    kmeans = Ai4r::Clusterers::KMeans.new.set_parameters(random_seed: @data).build(DATA, 3)
    @fitness = -kmeans.sse
  end

  def self.seed
    new(RANGE.to_a.sample)
  end

  def self.reproduce(parent_a, parent_b, _rate = 0.7)
    new([parent_a.data, parent_b.data].sample)
  end

  def self.mutate(chrom, rate = 0.3)
    return unless rand < rate

    chrom.data = RANGE.to_a.sample
    chrom.instance_variable_set(:@fitness, nil)
  end
end

search = Ai4r::GeneticAlgorithm::GeneticSearch.new(6, 5, SeedChromosome, 0.1, 0.7)
best = search.run
puts(-best.fitness)
