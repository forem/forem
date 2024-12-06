# frozen_string_literal: true

module JaroWinkler
  DEFAULT_ADJ_TABLE = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
  [
    %w[A E], %w[A I], %w[A O], %w[A U], %w[B V], %w[E I], %w[E O], %w[E U], %w[I O],
    %w[I U], %w[O U], %w[I Y], %w[E Y], %w[C G], %w[E F], %w[W U], %w[W V], %w[X K],
    %w[S Z], %w[X S], %w[Q C], %w[U V], %w[M N], %w[L I], %w[Q O], %w[P R], %w[I J],
    %w[2 Z], %w[5 S], %w[8 B], %w[1 I], %w[1 L], %w[0 O], %w[0 Q], %w[C K], %w[G J],
    ['E', ' '], ['Y', ' '], ['S', ' ']
  ].each do |s1, s2|
    DEFAULT_ADJ_TABLE[s1][s2] = DEFAULT_ADJ_TABLE[s2][s1] = true
  end
end
