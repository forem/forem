# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Stan < RegexLexer
      title "Stan"
      desc 'Stan Modeling Language (mc-stan.org)'
      tag 'stan'
      filenames '*.stan', '*.stanfunctions'

      # optional comment or whitespace
      WS = %r((?:\s|//.*?\n|/[*].*?[*]/)+)
      ID = /[a-zA-Z_][a-zA-Z0-9_]*/
      RT = /(?:(?:[a-z_]\s*(?:\[[0-9, ]\])?)\s+)*/
      OP = Regexp.new([
        # Assigment operators
        "=",

        # Comparison operators
        "<", "<=", ">", ">=", "==", "!=",

        # Boolean operators
        "!", "&&", "\\|\\|",

        # Real-valued arithmetic operators
        "\\+", "-", "\\*", "/", "\\^",

        # Transposition operator
        "'",

        # Elementwise functions
        "\\.\\+", "\\.-", "\\.\\*", "\\./", "\\.\\^",

        # Matrix division operators
        "\\\\",

        # Compound assigment operators
        "\\+=", "-=", "\\*=", "/=", "\\.\\*=", "\\./=",

        # Sampling
        "~",

        # Conditional operator
        "\\?", ":"
      ].join("|"))

      def self.keywords
        @keywords ||= Set.new %w(
          if else while for break continue print reject return
        )
      end

      def self.types
        @types ||= Set.new %w(
          int real vector ordered positive_ordered simplex unit_vector
          row_vector matrix cholesky_factor_corr cholesky_factor_cov corr_matrix
          cov_matrix data void complex array
        )
      end

      def self.reserved
        @reserved ||= Set.new [
          # Reserved words from Stan language
          "for", "in", "while", "repeat", "until", "if", "then", "else", "true",
          "false", "target", "functions", "model", "data", "parameters",
          "quantities", "transformed", "generated",

          # Reserved names from Stan implementation
          "var", "fvar", "STAN_MAJOR", "STAN_MINOR", "STAN_PATCH",
          "STAN_MATH_MAJOR", "STAN_MATH_MINOR", "STAN_MATH_PATCH",

          # Reserved names from C++
          "alignas", "alignof", "and", "and_eq", "asm", "auto", "bitand",
          "bitor", "bool", "break", "case", "catch", "char", "char16_t",
          "char32_t", "class", "compl", "const", "constexpr", "const_cast",
          "continue", "decltype", "default", "delete", "do", "double",
          "dynamic_cast", "else", "enum", "explicit", "export", "extern",
          "false", "float", "for", "friend", "goto", "if", "inline", "int",
          "long", "mutable", "namespace", "new", "noexcept", "not", "not_eq",
          "nullptr", "operator", "or", "or_eq", "private", "protected",
          "public", "register", "reinterpret_cast", "return", "short", "signed",
          "sizeof", "static", "static_assert", "static_cast", "struct",
          "switch", "template", "this", "thread_local", "throw", "true", "try",
          "typedef", "typeid", "typename", "union", "unsigned", "using",
          "virtual", "void", "volatile", "wchar_t", "while", "xor", "xor_eq"
        ]
      end

      def self.builtin_functions
        @builtin_functions ||= Set.new [
          # Integer-Valued Basic Functions

          ## Absolute functions
          "abs", "int_step",

          ## Bound functions
          "min", "max",

          ## Size functions
          "size",

          # Real-Valued Basic Functions

          ## Log probability function
          "target", "get_lp",

          ## Logical functions
          "step", "is_inf", "is_nan",

          ## Step-like functions
          "fabs", "fdim", "fmin", "fmax", "fmod", "floor", "ceil", "round",
          "trunc",

          ## Power and logarithm functions
          "sqrt", "cbrt", "square", "exp", "exp2", "log", "log2", "log10",
          "pow", "inv", "inv_sqrt", "inv_square",

          ## Trigonometric functions
          "hypot", "cos", "sin", "tan", "acos", "asin", "atan", "atan2",

          ## Hyperbolic trigonometric functions
          "cosh", "sinh", "tanh", "acosh", "asinh", "atanh",

          ## Link functions
          "logit", "inv_logit", "inv_cloglog",

          ## Probability-related functions
          "erf", "erfc", "Phi", "inv_Phi", "Phi_approx", "binary_log_loss",
          "owens_t",

          ## Combinatorial functions
          "beta", "inc_beta", "lbeta", "tgamma", "lgamma", "digamma",
          "trigamma", "lmgamma", "gamma_p", "gamma_q",
          "binomial_coefficient_log", "choose", "bessel_first_kind",
          "bessel_second_kind", "modified_bessel_first_kind",
          "log_modified_bessel_first_kind", "modified_bessel_second_kind",
          "falling_factorial", "lchoose", "log_falling_factorial",
          "rising_factorial", "log_rising_factorial",

          ## Composed functions
          "expm1", "fma", "multiply_log", "ldexp", "lmultiply", "log1p",
          "log1m", "log1p_exp", "log1m_exp", "log_diff_exp", "log_mix",
          "log_sum_exp", "log_inv_logit", "log_inv_logit_diff",
          "log1m_inv_logit",

          ## Special functions
          "lambert_w0", "lambert_wm1",

          # Complex-Valued Basic Functions

          ## Complex constructors and accessors
          "to_complex", "get_real", "get_imag",

          ## Complex special functions
          "arg", "norm", "conj", "proj", "polar",

          # Array Operations

          ## Reductions
          "sum", "prod", "log_sum_exp", "mean", "variance", "sd", "distance",
          "squared_distance", "quantile",

          ## Array size and dimension function
          "dims", "num_elements",

          ## Array broadcasting
          "rep_array",

          ## Array concatenation
          "append_array",

          ## Sorting functions
          "sort_asc", "sort_desc", "sort_indices_asc", "sort_indices_desc",
          "rank",

          ## Reversing functions
          "reverse",

          # Matrix Operations

          ## Integer-valued matrix size functions
          "num_elements", "rows", "cols",

          ## Dot products and specialized products
          "dot_product", "columns_dot_product", "rows_dot_product", "dot_self",
          "columns_dot_self", "rows_dot_self", "tcrossprod", "crossprod",
          "quad_form", "quad_form_diag", "quad_form_sym", "trace_quad_form",
          "trace_gen_quad_form", "multiply_lower_tri_self_transpose",
          "diag_pre_multiply", "diag_post_multiply",

          ## Broadcast functions
          "rep_vector", "rep_row_vector", "rep_matrix",
          "symmetrize_from_lower_tri",

          ## Diagonal matrix functions
          "add_diag", "diagonal", "diag_matrix", "identity_matrix",

          ## Container construction functions
          "linspaced_array", "linspaced_int_array", "linspaced_vector",
          "linspaced_row_vector", "one_hot_int_array", "one_hot_array",
          "one_hot_vector", "one_hot_row_vector", "ones_int_array",
          "ones_array", "ones_vector", "ones_row_vector", "zeros_int_array",
          "zeros_array", "zeros_vector", "zeros_row_vector", "uniform_simplex",

          ## Slicing and blocking functions
          "col", "row", "block", "sub_col", "sub_row", "head", "tail",
          "segment",

          ## Matrix concatenation
          "append_col", "append_row",

          ## Special matrix functions
          "softmax", "log_softmax", "cumulative_sum",

          ## Covariance functions
          "cov_exp_quad",

          ## Linear algebra functions and solvers
          "mdivide_left_tri_low", "mdivide_right_tri_low", "mdivide_left_spd",
          "mdivide_right_spd", "matrix_exp", "matrix_exp_multiply",
          "scale_matrix_exp_multiply", "matrix_power", "trace", "determinant",
          "log_determinant", "inverse", "inverse_spd", "chol2inv",
          "generalized_inverse", "eigenvalues_sym", "eigenvectors_sym",
          "qr_thin_Q", "qr_thin_R", "qr_Q", "qr_R", "cholseky_decompose",
          "singular_values", "svd_U", "svd_V",

          # Sparse Matrix Operations

          ## Conversion functions
          "csr_extract_w", "csr_extract_v", "csr_extract_u",
          "csr_to_dense_matrix",

          ## Sparse matrix arithmetic
          "csr_matrix_times_vector",

          # Mixed Operations
          "to_matrix", "to_vector", "to_row_vector", "to_array_2d",
          "to_array_1d",

          # Higher-Order Functions

          ## Algebraic equation solver
          "algebra_solver", "algebra_solver_newton",

          ## Ordinary differential equation
          "ode_rk45", "ode_rk45_tol", "ode_ckrk", "ode_ckrk_tol", "ode_adams",
          "ode_adams_tol", "ode_bdf", "ode_bdf_tol", "ode_adjoint_tol_ctl",

          ## 1D integrator
          "integrate_1d",

          ## Reduce-sum function
          "reduce_sum", "reduce_sum_static",

          ## Map-rect function
          "map_rect",

          # Deprecated Functions
          "integrate_ode_rk45", "integrate_ode", "integrate_ode_adams",
          "integrate_ode_bdf",

          # Hidden Markov Models
          "hmm_marginal", "hmm_latent_rng", "hmm_hidden_state_prob"
        ]
      end

      def self.distributions
        @distributions ||= Set.new(
          [
            # Discrete Distributions

            ## Binary Distributions
            "bernoulli", "bernoulli_logit", "bernoulli_logit_glm",

            ## Bounded Discrete Distributions
            "binomial", "binomial_logit", "beta_binomial", "hypergeometric",
            "categorical", "categorical_logit_glm", "discrete_range",
            "ordered_logistic", "ordered_logistic_glm", "ordered_probit",

            ## Unbounded Discrete Distributions
            "neg_binomial", "neg_binomial_2", "neg_binomial_2_log",
            "neg_binomial_2_log_glm", "poisson", "poisson_log",
            "poisson_log_glm",

            ## Multivariate Discrete Distributions
            "multinomial", "multinomial_logit",

            # Continuous Distributions

            ## Unbounded Continuous Distributions
            "normal", "std_normal", "normal_id_glm", "exp_mod_normal",
            "skew_normal", "student_t", "cauchy", "double_exponential",
            "logistic", "gumbel", "skew_double_exponential",

            ## Positive Continuous Distributions
            "lognormal", "chi_square", "inv_chi_square",
            "scaled_inv_chi_square", "exponential", "gamma", "inv_gamma",
            "weibull", "frechet", "rayleigh",

            ## Positive Lower-Bounded Distributions
            "pareto", "pareto_type_2", "wiener",

            ## Continuous Distributions on [0, 1]
            "beta", "beta_proportion",

            ## Circular Distributions
            "von_mises",

            ## Bounded Continuous Distributions
            "uniform",

            ## Distributions over Unbounded Vectors
            "multi_normal", "multi_normal_prec", "multi_normal_cholesky",
            "multi_gp", "multi_gp_cholesky", "multi_student_t",
            "gaussian_dlm_obs",

            ## Simplex Distributions
            "dirichlet",

            ## Correlation Matrix Distributions
            "lkj_corr", "lkj_corr_cholesky",

            ## Covariance Matrix Distributions
            "wishart", "inv_wishart"
          ].product([
            "", "_lpmf", "_lupmf", "_lpdf", "_lcdf", "_lccdf", "_rng", "_log",
            "_cdf_log", "_ccdf_log"
          ]).map {|s| "#{s[0]}#{s[1]}"}
        )
      end

      def self.constants
        @constants ||= Set.new [
          # Mathematical constants
          "pi", "e", "sqrt2", "log2", "log10",

          # Special values
          "not_a_number", "positive_infinity", "negative_infinity",
          "machine_precision"
        ]
      end

      state :root do
        mixin :whitespace
        rule %r/#include/, Comment::Preproc, :include
        rule %r/#.*$/, Generic::Deleted
        rule %r(
          functions
          |(?:transformed\s+)?data
          |(?:transformed\s+)?parameters
          |model
          |generated\s+quantities
        )x, Name::Namespace
        rule %r(\{), Punctuation, :bracket_scope
        mixin :scope
      end

      state :include do
        rule %r((\s+)(\S+)(\s*)) do |m|
          token Text, m[1]                          
          token Comment::PreprocFile, m[2]           
          token Text, m[3]
          pop!
        end
      end

      state :whitespace do
        rule %r(\n+)m, Text
        rule %r(//(\\.|.)*?$), Comment::Single
        mixin :inline_whitespace
      end

      state :inline_whitespace do
        rule %r([ \t\r]+), Text
        rule %r(/(\\\n)?[*].*?[*](\\\n)?/)m, Comment::Multiline
      end

      state :statements do
        mixin :whitespace
        rule %r/#include/, Comment::Preproc, :include
        rule %r/#.*$/, Generic::Deleted
        rule %r("), Str, :string
        rule %r(
          (
            ((\d+[.]\d*|[.]?\d+)e[+-]?\d+|\d*[.]\d+|\d+) 
            (#{WS})[+-](#{WS})
            ((\d+[.]\d*|[.]?\d+)e[+-]?\d+|\d*[.]\d+|\d+)i
          )
          |((\d+[.]\d*|[.]?\d+)e[+-]?\d+|\d*[.]\d+|\d+)i
          |((\d+[.]\d*|[.]?\d+)e[+-]?\d+|\d*[.]\d+) 
        )mx, Num::Float
        rule %r/\d+/, Num::Integer
        rule %r(\*/), Error
        rule OP, Operator
        rule %r([\[\],.;]), Punctuation
        rule %r([|](?![|])), Punctuation
        rule %r(T\b), Keyword::Reserved
        rule %r((lower|upper)\b), Name::Attribute
        rule ID do |m|
          name = m[0]

          if self.class.keywords.include? name
            token Keyword
          elsif self.class.types.include? name
            token Keyword::Type
          elsif self.class.reserved.include? name
            token Keyword::Reserved
          else
            token Name::Variable
          end
        end
      end

      state :scope do
        mixin :whitespace
        rule %r(
          (#{RT})         # Return type
          (#{ID})         # Function name
          (?=\([^;]*?\))  # Signature or arguments
        )mx do |m|
          recurse m[1]

          name = m[2]
          if self.class.builtin_functions.include? name
            token Name::Builtin, name
          elsif self.class.distributions.include? name
            token Name::Builtin, name
          elsif self.class.constants.include? name
            token Keyword::Constant
          else
            token Name::Function, name
          end
        end
        rule %r(\{), Punctuation, :bracket_scope
        rule %r(\(), Punctuation, :parens_scope
        mixin :statements
      end

      state :bracket_scope do
        mixin :scope
        rule %r(\}), Punctuation, :pop!
      end

      state :parens_scope do
        mixin :scope
        rule %r(\)), Punctuation, :pop!
      end
    end
  end
end
