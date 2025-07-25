# frozen_string_literal: true

require_relative 'ai4r/version'

# Data
require_relative 'ai4r/data/data_set'
require_relative 'ai4r/data/statistics'
require_relative 'ai4r/data/proximity'
require_relative 'ai4r/data/parameterizable'

# Clusterers
require_relative 'ai4r/clusterers/clusterer'
require_relative 'ai4r/clusterers/k_means'
require_relative 'ai4r/clusterers/bisecting_k_means'
require_relative 'ai4r/clusterers/single_linkage'
require_relative 'ai4r/clusterers/complete_linkage'
require_relative 'ai4r/clusterers/average_linkage'
require_relative 'ai4r/clusterers/weighted_average_linkage'
require_relative 'ai4r/clusterers/centroid_linkage'
require_relative 'ai4r/clusterers/median_linkage'
require_relative 'ai4r/clusterers/ward_linkage'
require_relative 'ai4r/clusterers/ward_linkage_hierarchical'
require_relative 'ai4r/clusterers/diana'
require_relative 'ai4r/clusterers/dbscan'

# Classifiers
require_relative 'ai4r/classifiers/classifier'
require_relative 'ai4r/classifiers/id3'
require_relative 'ai4r/classifiers/multilayer_perceptron'
require_relative 'ai4r/classifiers/prism'
require_relative 'ai4r/classifiers/one_r'
require_relative 'ai4r/classifiers/zero_r'
require_relative 'ai4r/classifiers/hyperpipes'
require_relative 'ai4r/classifiers/naive_bayes'
require_relative 'ai4r/classifiers/ib1'
require_relative 'ai4r/classifiers/random_forest'
require_relative 'ai4r/classifiers/gradient_boosting'
require_relative 'ai4r/classifiers/support_vector_machine'

# Neural networks
require_relative 'ai4r/neural_network/backpropagation'
require_relative 'ai4r/neural_network/hopfield'
require_relative 'ai4r/neural_network/transformer'

# Genetic Algorithms
require_relative 'ai4r/genetic_algorithm/genetic_algorithm'

# Reinforcement Learning
require_relative 'ai4r/reinforcement/q_learning'
require_relative 'ai4r/reinforcement/policy_iteration'

# Search
require_relative 'ai4r/search/bfs'
require_relative 'ai4r/search/dfs'
require_relative 'ai4r/search/mcts'
require_relative 'ai4r/search'

# Hidden Markov Models
require_relative 'ai4r/hmm/hidden_markov_model'

# SOM
require_relative 'ai4r/som/som'

# Search Algorithms
