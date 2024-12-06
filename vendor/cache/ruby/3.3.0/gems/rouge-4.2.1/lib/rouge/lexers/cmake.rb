# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class CMake < RegexLexer
      title 'CMake'
      desc 'The cross-platform, open-source build system'
      tag 'cmake'
      filenames 'CMakeLists.txt', '*.cmake'
      mimetypes 'text/x-cmake'

      SPACE = '[ \t]'
      BRACKET_OPEN = '\[=*\['

      STATES_MAP = {
        :root => Text,
        :bracket_string => Str::Double,
        :quoted_argument => Str::Double,
        :bracket_comment => Comment::Multiline,
        :variable_reference => Name::Variable,
      }

      BUILTIN_COMMANDS = Set.new %w[
        add_compile_definitions
        add_compile_options
        add_custom_command
        add_custom_target
        add_definitions
        add_dependencies
        add_executable
        add_library
        add_link_options
        add_subdirectory
        add_test
        aux_source_directory
        break
        build_command
        build_name
        cmake_host_system_information
        cmake_language
        cmake_minimum_required
        cmake_parse_arguments
        cmake_policy
        configure_file
        create_test_sourcelist
        define_property
        else
        elseif
        enable_language
        enable_testing
        endforeach
        endfunction
        endif
        endmacro
        endwhile
        exec_program
        execute_process
        export
        export_library_dependencies
        file
        find_file
        find_library
        find_package
        find_path
        find_program
        fltk_wrap_ui
        foreach
        function
        get_cmake_property
        get_directory_property
        get_filename_component
        get_property
        get_source_file_property
        get_target_property
        get_test_property
        if
        include
        include_directories
        include_external_msproject
        include_guard
        include_regular_expression
        install
        install_files
        install_programs
        install_targets
        link_directories
        link_libraries
        list
        load_cache
        load_command
        macro
        make_directory
        mark_as_advanced
        math
        message
        option
        output_required_files
        project
        qt_wrap_cpp
        qt_wrap_ui
        remove
        remove_definitions
        return
        separate_arguments
        set
        set_directory_properties
        set_property
        set_source_files_properties
        set_target_properties
        set_tests_properties
        site_name
        source_group
        string
        subdir_depends
        subdirs
        target_compile_definitions
        target_compile_features
        target_compile_options
        target_include_directories
        target_link_directories
        target_link_libraries
        target_link_options
        target_precompile_headers
        target_sources
        try_compile
        try_run
        unset
        use_mangled_mesa
        utility_source
        variable_requires
        variable_watch
        while
        write_file
      ]

      state :default do
        rule %r/\r\n?|\n/ do
          token STATES_MAP[state.name.to_sym]
        end
        rule %r/./ do
          token STATES_MAP[state.name.to_sym]
        end
      end

      state :variable_interpolation do
        rule %r/\$\{/ do
          token Str::Interpol
          push :variable_reference
        end
      end

      state :bracket_close do
        rule %r/\]=*\]/ do |m|
          token STATES_MAP[state.name.to_sym]
          goto :root if m[0].length == @bracket_len
        end
      end

      state :root do
        mixin :variable_interpolation

        rule %r/#{SPACE}/, Text
        rule %r/[()]/, Punctuation

        rule %r/##{BRACKET_OPEN}/ do |m|
          token Comment::Multiline
          @bracket_len = m[0].length - 1 # decount '#'
          goto :bracket_comment
        end
        rule %r/#{BRACKET_OPEN}/ do |m|
          token Str::Double
          @bracket_len = m[0].length
          goto :bracket_string
        end

        rule %r/\\"/, Text
        rule %r/"/, Str::Double, :quoted_argument

        rule %r/([A-Za-z_][A-Za-z0-9_]*)(#{SPACE}*)(\()/ do |m|
          groups BUILTIN_COMMANDS.include?(m[1]) ? Name::Builtin : Name::Function, Text, Punctuation
        end

        rule %r/#.*/, Comment::Single

        mixin :default
      end

      state :bracket_string do
        mixin :bracket_close
        mixin :variable_interpolation
        mixin :default
      end

      state :bracket_comment do
        mixin :bracket_close
        mixin :default
      end

      state :variable_reference do
        mixin :variable_interpolation

        rule %r/}/, Str::Interpol, :pop!

        mixin :default
      end

      state :quoted_argument do
        mixin :variable_interpolation

        rule %r/"/, Str::Double, :root
        rule %r/\\[()#" \\$@^trn;]/, Str::Escape

        mixin :default
      end
    end
  end
end
