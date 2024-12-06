# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'groovy.rb'

    class Gradle < Groovy
      title "Gradle"
      desc "A powerful build system for the JVM"

      tag 'gradle'
      filenames '*.gradle'
      mimetypes 'text/x-gradle'

      def self.keywords
        @keywords ||= super + Set.new(%w(
          allprojects artifacts buildscript configuration dependencies
          repositories sourceSets subprojects publishing
        ))
      end

      def self.types
        @types ||= super + Set.new(%w(
          Project Task Gradle Settings Script JavaToolChain SourceSet
          SourceSetOutput IncrementalTaskInputs Configuration
          ResolutionStrategy ArtifactResolutionQuery ComponentSelection
          ComponentSelectionRules ConventionProperty ExtensionAware
          ExtraPropertiesExtension PublishingExtension IvyPublication
          IvyArtifact IvyArtifactSet IvyModuleDescriptorSpec
          MavenPublication MavenArtifact MavenArtifactSet MavenPom
          PluginDependenciesSpec PluginDependencySpec ResourceHandler
          TextResourceFactory
        ))
      end
    end
  end
end
