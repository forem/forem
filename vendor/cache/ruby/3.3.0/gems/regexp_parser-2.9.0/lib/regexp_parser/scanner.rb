# -*- warn-indent:false;  -*-
#
# THIS IS A GENERATED FILE, DO NOT EDIT DIRECTLY
#
# This file was generated from scanner.rl
# by running `bundle exec rake ragel:rb`


require 'regexp_parser/scanner/errors/scanner_error'
require 'regexp_parser/scanner/errors/premature_end_error'
require 'regexp_parser/scanner/errors/validation_error'

class Regexp::Scanner
  # Scans the given regular expression text, or Regexp object and collects the
  # emitted token into an array that gets returned at the end. If a block is
  # given, it gets called for each emitted token.
  #
  # This method may raise errors if a syntax error is encountered.
  # --------------------------------------------------------------------------
  def self.scan(input_object, options: nil, collect_tokens: true, &block)
    new.scan(input_object, options: options, collect_tokens: collect_tokens, &block)
  end

  def scan(input_object, options: nil, collect_tokens: true, &block)
    self.collect_tokens = collect_tokens
    self.literal_run = nil
    stack = []

    input = input_object.is_a?(Regexp) ? input_object.source : input_object
    self.free_spacing = free_spacing?(input_object, options)
    self.spacing_stack = [{:free_spacing => free_spacing, :depth => 0}]

    data  = input.unpack("c*")
    eof   = data.length

    self.tokens = []
    self.block  = block

    self.set_depth = 0
    self.group_depth = 0
    self.conditional_stack = []
    self.char_pos = 0

class << self
	attr_accessor :_re_scanner_trans_keys
	private :_re_scanner_trans_keys, :_re_scanner_trans_keys=
end
self._re_scanner_trans_keys = [
0,0,-128,-65,-128,-65,
-128,-65,41,41,39,
57,39,39,33,62,
62,62,39,60,39,57,
39,39,48,57,39,
57,48,57,39,57,
33,62,62,62,48,57,
43,62,48,57,48,
62,39,60,39,57,
39,39,48,57,39,57,
48,57,39,57,33,
62,62,62,48,57,
43,62,48,57,48,62,
48,57,48,125,44,
125,123,123,9,122,
9,125,9,122,-128,-65,
-128,-65,38,38,58,
93,58,93,-128,-65,
-128,-65,45,45,92,92,
92,92,45,45,92,
92,92,92,48,123,
48,102,48,102,48,102,
48,102,9,125,9,
125,9,125,9,125,
9,125,9,125,48,123,
39,39,41,41,41,
57,62,62,-128,127,
-62,-12,1,127,1,127,
9,32,33,126,10,
10,63,63,33,126,
33,126,62,62,43,63,
43,63,43,63,65,
122,44,57,68,119,
80,112,-62,125,-128,-65,
-128,-65,-128,-65,38,
38,38,93,58,58,
48,120,48,55,48,55,
-62,125,-128,-65,-128,
-65,-128,-65,48,55,
48,55,48,57,77,77,
45,45,0,0,67,
99,45,45,0,0,
92,92,48,102,39,60,
39,57,48,57,41,
57,33,62,0
]

class << self
	attr_accessor :_re_scanner_key_spans
	private :_re_scanner_key_spans, :_re_scanner_key_spans=
end
self._re_scanner_key_spans = [
0,64,64,64,1,19,1,30,
1,22,19,1,10,19,10,19,
30,1,10,20,10,15,22,19,
1,10,19,10,19,30,1,10,
20,10,15,10,78,82,1,114,
117,114,64,64,1,36,36,64,
64,1,1,1,1,1,1,76,
55,55,55,55,117,117,117,117,
117,117,76,1,1,17,1,256,
51,127,127,24,94,1,1,94,
94,1,21,21,21,58,14,52,
33,188,64,64,64,1,56,1,
73,8,8,188,64,64,64,8,
8,10,1,1,0,33,1,0,
1,55,22,19,10,17,30
]

class << self
	attr_accessor :_re_scanner_index_offsets
	private :_re_scanner_index_offsets, :_re_scanner_index_offsets=
end
self._re_scanner_index_offsets = [
0,0,65,130,195,197,217,219,
250,252,275,295,297,308,328,339,
359,390,392,403,424,435,451,474,
494,496,507,527,538,558,589,591,
602,623,634,650,661,740,823,825,
940,1058,1173,1238,1303,1305,1342,1379,
1444,1509,1511,1513,1515,1517,1519,1521,
1598,1654,1710,1766,1822,1940,2058,2176,
2294,2412,2530,2607,2609,2611,2629,2631,
2888,2940,3068,3196,3221,3316,3318,3320,
3415,3510,3512,3534,3556,3578,3637,3652,
3705,3739,3928,3993,4058,4123,4125,4182,
4184,4258,4267,4276,4465,4530,4595,4660,
4669,4678,4689,4691,4693,4694,4728,4730,
4731,4733,4789,4812,4832,4843,4861
]

class << self
	attr_accessor :_re_scanner_indicies
	private :_re_scanner_indicies, :_re_scanner_indicies=
end
self._re_scanner_indicies = [
1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,
1,1,1,1,1,1,1,1,
0,2,2,2,2,2,2,2,
2,2,2,2,2,2,2,2,
2,2,2,2,2,2,2,2,
2,2,2,2,2,2,2,2,
2,2,2,2,2,2,2,2,
2,2,2,2,2,2,2,2,
2,2,2,2,2,2,2,2,
2,2,2,2,2,2,2,2,
2,0,3,3,3,3,3,3,
3,3,3,3,3,3,3,3,
3,3,3,3,3,3,3,3,
3,3,3,3,3,3,3,3,
3,3,3,3,3,3,3,3,
3,3,3,3,3,3,3,3,
3,3,3,3,3,3,3,3,
3,3,3,3,3,3,3,3,
3,3,0,6,5,8,7,7,
7,7,7,4,7,7,4,4,
4,4,4,4,4,4,4,4,
7,8,7,10,9,9,9,9,
9,9,9,9,9,9,9,4,
9,9,4,4,4,4,4,4,
4,4,4,4,9,9,9,11,
8,9,8,9,13,12,12,12,
12,12,12,12,12,12,12,12,
12,12,12,12,12,12,12,12,
12,14,12,16,15,15,15,15,
15,17,15,15,18,18,18,18,
18,18,18,18,18,18,15,16,
15,18,18,18,18,18,18,18,
18,18,18,12,16,12,12,12,
19,12,19,12,12,18,18,18,
18,18,18,18,18,18,18,12,
20,20,20,20,20,20,20,20,
20,20,12,16,12,12,12,12,
12,12,12,12,20,20,20,20,
20,20,20,20,20,20,12,12,
21,21,21,21,21,21,21,21,
21,21,21,22,21,21,23,23,
23,23,23,23,23,23,23,23,
21,21,21,21,16,21,16,21,
23,23,23,23,23,23,23,23,
23,23,12,24,12,24,12,12,
23,23,23,23,23,23,23,23,
23,23,12,12,12,12,16,12,
25,25,25,25,25,25,25,25,
25,25,12,25,25,25,25,25,
25,25,25,25,25,12,12,12,
12,16,12,26,12,12,12,12,
12,12,12,12,12,12,12,12,
12,12,12,12,12,12,12,12,
27,12,29,28,28,28,28,28,
30,28,28,31,31,31,31,31,
31,31,31,31,31,28,29,28,
31,31,31,31,31,31,31,31,
31,31,12,29,12,12,12,32,
12,32,12,12,31,31,31,31,
31,31,31,31,31,31,12,33,
33,33,33,33,33,33,33,33,
33,12,29,12,12,12,12,12,
12,12,12,33,33,33,33,33,
33,33,33,33,33,12,12,34,
34,34,34,34,34,34,34,34,
34,34,35,34,34,36,36,36,
36,36,36,36,36,36,36,34,
34,34,34,29,34,29,34,36,
36,36,36,36,36,36,36,36,
36,12,37,12,37,12,12,36,
36,36,36,36,36,36,36,36,
36,12,12,12,12,29,12,38,
38,38,38,38,38,38,38,38,
38,12,38,38,38,38,38,38,
38,38,38,38,12,12,12,12,
29,12,40,40,40,40,40,40,
40,40,40,40,39,40,40,40,
40,40,40,40,40,40,40,39,
39,39,39,39,39,39,39,39,
39,39,39,39,39,39,39,39,
39,39,39,39,39,39,39,39,
39,39,39,39,39,39,39,39,
39,39,39,39,39,39,39,39,
39,39,39,39,39,39,39,39,
39,39,39,39,39,39,39,39,
39,39,39,39,39,39,39,39,
39,39,41,39,40,39,39,39,
42,42,42,42,42,42,42,42,
42,42,39,39,39,39,39,39,
39,39,39,39,39,39,39,39,
39,39,39,39,39,39,39,39,
39,39,39,39,39,39,39,39,
39,39,39,39,39,39,39,39,
39,39,39,39,39,39,39,39,
39,39,39,39,39,39,39,39,
39,39,39,39,39,39,39,39,
39,39,39,39,39,41,39,43,
44,45,45,45,45,45,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
45,44,44,44,44,44,44,44,
44,44,44,44,44,45,45,44,
45,45,45,45,45,45,45,45,
45,45,44,44,44,45,44,44,
44,45,45,45,45,45,45,45,
45,45,45,45,45,45,45,45,
45,45,45,45,45,45,45,45,
45,45,45,44,44,44,46,45,
44,45,45,45,45,45,45,45,
45,45,45,45,45,45,45,45,
45,45,45,45,45,45,45,45,
45,45,45,44,45,45,45,45,
45,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,45,44,44,44,44,
44,44,44,44,44,44,44,44,
45,45,44,45,45,45,45,45,
45,45,45,45,45,44,44,44,
45,44,44,44,45,45,45,45,
45,45,45,45,45,45,45,45,
45,45,45,45,45,45,45,45,
45,45,45,45,45,45,44,44,
44,44,45,44,45,45,45,45,
45,45,45,45,45,45,45,45,
45,45,45,45,45,45,45,45,
45,45,45,45,45,45,44,44,
47,44,45,45,45,45,45,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,45,44,44,44,44,44,44,
44,44,44,44,44,44,45,45,
44,45,45,45,45,45,45,45,
45,45,45,44,44,44,45,44,
44,44,45,45,45,45,45,45,
45,45,45,45,45,45,45,45,
45,45,45,45,45,45,45,45,
45,45,45,45,44,44,44,44,
45,44,45,45,45,45,45,45,
45,45,45,45,45,45,45,45,
45,45,45,45,45,45,45,45,
45,45,45,45,44,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,48,50,50,
50,50,50,50,50,50,50,50,
50,50,50,50,50,50,50,50,
50,50,50,50,50,50,50,50,
50,50,50,50,50,50,50,50,
50,50,50,50,50,50,50,50,
50,50,50,50,50,50,50,50,
50,50,50,50,50,50,50,50,
50,50,50,50,50,50,48,52,
51,55,54,54,54,54,54,54,
54,54,54,54,54,54,54,54,
54,54,54,54,54,54,54,54,
54,54,54,54,54,54,54,54,
54,54,56,54,56,54,55,54,
54,54,54,54,54,54,54,54,
54,54,54,54,54,54,54,54,
54,54,54,54,54,54,54,54,
54,54,54,54,54,54,54,56,
54,57,54,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,58,60,60,60,60,
60,60,60,60,60,60,60,60,
60,60,60,60,60,60,60,60,
60,60,60,60,60,60,60,60,
60,60,60,60,60,60,60,60,
60,60,60,60,60,60,60,60,
60,60,60,60,60,60,60,60,
60,60,60,60,60,60,60,60,
60,60,60,60,58,61,44,63,
62,65,62,66,44,68,67,70,
67,71,71,71,71,71,71,71,
71,71,71,44,44,44,44,44,
44,44,71,71,71,71,71,71,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,71,71,71,71,71,71,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,72,44,73,73,
73,73,73,73,73,73,73,73,
44,44,44,44,44,44,44,73,
73,73,73,73,73,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,73,
73,73,73,73,73,44,74,74,
74,74,74,74,74,74,74,74,
44,44,44,44,44,44,44,74,
74,74,74,74,74,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,74,
74,74,74,74,74,44,75,75,
75,75,75,75,75,75,75,75,
44,44,44,44,44,44,44,75,
75,75,75,75,75,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,75,
75,75,75,75,75,44,76,76,
76,76,76,76,76,76,76,76,
44,44,44,44,44,44,44,76,
76,76,76,76,76,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,76,
76,76,76,76,76,44,72,72,
72,72,72,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,72,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,77,77,77,
77,77,77,77,77,77,77,44,
44,44,44,44,44,44,77,77,
77,77,77,77,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,77,77,
77,77,77,77,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,75,44,72,72,72,72,
72,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,72,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,78,78,78,78,78,
78,78,78,78,78,44,44,44,
44,44,44,44,78,78,78,78,
78,78,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,78,78,78,78,
78,78,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
75,44,72,72,72,72,72,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,72,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,79,79,79,79,79,79,79,
79,79,79,44,44,44,44,44,
44,44,79,79,79,79,79,79,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,79,79,79,79,79,79,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,75,44,
72,72,72,72,72,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,72,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,80,
80,80,80,80,80,80,80,80,
80,44,44,44,44,44,44,44,
80,80,80,80,80,80,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
80,80,80,80,80,80,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,75,44,72,72,
72,72,72,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,72,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,81,81,81,
81,81,81,81,81,81,81,44,
44,44,44,44,44,44,81,81,
81,81,81,81,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,81,81,
81,81,81,81,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,75,44,72,72,72,72,
72,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,72,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
75,44,83,83,83,83,83,83,
83,83,83,83,82,82,82,82,
82,82,82,83,83,83,83,83,
83,82,82,82,82,82,82,82,
82,82,82,82,82,82,82,82,
82,82,82,82,82,82,82,82,
82,82,82,83,83,83,83,83,
83,82,82,82,82,82,82,82,
82,82,82,82,82,82,82,82,
82,82,82,82,82,44,82,86,
85,87,84,87,84,84,84,84,
84,84,88,88,88,88,88,88,
88,88,88,88,84,86,89,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,2,2,2,2,2,2,2,
2,2,2,2,2,2,2,2,
2,2,2,2,2,2,2,2,
2,2,2,2,2,2,2,3,
3,3,3,3,3,3,3,3,
3,3,3,3,3,3,3,90,
90,90,90,90,44,44,44,44,
44,44,44,44,44,44,44,44,
91,91,91,91,91,91,91,91,
92,92,92,92,92,91,91,91,
91,91,91,91,91,91,91,91,
91,91,91,91,91,91,91,93,
94,94,95,96,94,94,94,97,
98,99,100,94,94,101,94,94,
94,94,94,94,94,94,94,94,
94,94,94,94,94,94,102,94,
94,94,94,94,94,94,94,94,
94,94,94,94,94,94,94,94,
94,94,94,94,94,94,94,94,
94,94,103,104,105,106,94,94,
94,94,94,94,94,94,94,94,
94,94,94,94,94,94,94,94,
94,94,94,94,94,94,94,94,
94,94,107,108,105,94,91,94,
2,2,2,2,2,2,2,2,
2,2,2,2,2,2,2,2,
2,2,2,2,2,2,2,2,
2,2,2,2,2,2,3,3,
3,3,3,3,3,3,3,3,
3,3,3,3,3,3,90,90,
90,90,90,109,91,91,91,91,
91,91,91,91,91,91,91,91,
91,91,91,91,91,91,91,91,
91,91,91,91,91,91,91,91,
91,91,91,109,109,109,109,109,
109,109,109,109,109,109,109,109,
109,109,109,109,109,109,109,109,
109,109,109,109,109,109,109,109,
109,109,109,109,109,109,109,109,
109,109,109,109,109,109,109,109,
109,109,109,109,109,109,109,109,
109,109,109,109,109,109,109,109,
109,109,109,109,109,109,109,109,
109,109,109,109,109,109,109,109,
109,109,109,109,109,109,109,109,
109,109,109,109,109,109,109,109,
109,109,91,109,91,91,91,91,
91,91,91,91,92,92,92,92,
92,91,91,91,91,91,91,91,
91,91,91,91,91,91,91,91,
91,91,91,93,110,110,110,110,
110,110,110,110,110,110,110,110,
110,110,110,110,110,110,110,110,
110,110,110,110,110,110,110,110,
110,110,110,110,110,110,110,110,
110,110,110,110,110,110,110,110,
110,110,110,110,110,110,110,110,
110,110,110,110,110,110,110,110,
110,110,110,110,110,110,110,110,
110,110,110,110,110,110,110,110,
110,110,110,110,110,110,110,110,
110,110,110,110,110,110,110,110,
110,110,91,110,93,93,93,93,
93,110,110,110,110,110,110,110,
110,110,110,110,110,110,110,110,
110,110,110,93,110,94,94,109,
109,94,94,94,109,109,109,109,
94,94,109,94,94,94,94,94,
94,94,94,94,94,94,94,94,
94,94,94,109,94,94,94,94,
94,94,94,94,94,94,94,94,
94,94,94,94,94,94,94,94,
94,94,94,94,94,94,94,109,
109,109,109,94,94,94,94,94,
94,94,94,94,94,94,94,94,
94,94,94,94,94,94,94,94,
94,94,94,94,94,94,94,109,
109,109,94,109,112,95,114,113,
10,116,5,116,116,116,117,118,
115,116,116,116,116,116,116,116,
116,116,116,116,116,116,116,116,
116,8,116,119,10,8,116,116,
116,116,116,116,116,116,116,116,
116,116,116,116,116,116,116,116,
116,116,116,116,116,116,116,116,
116,116,116,116,116,116,116,116,
116,116,116,116,116,116,116,116,
116,116,116,116,116,116,116,116,
116,116,116,116,116,116,116,116,
116,116,116,116,116,8,116,115,
116,115,116,116,116,115,115,115,
116,116,116,116,116,116,116,116,
116,116,116,116,116,116,116,116,
120,116,115,115,115,116,116,116,
116,116,116,116,116,116,116,116,
116,116,116,116,116,116,116,116,
116,116,116,116,116,116,116,116,
116,116,116,116,116,116,116,116,
116,116,116,116,116,116,116,116,
116,116,116,116,116,116,116,116,
116,116,116,116,116,116,116,116,
116,116,116,116,115,116,8,9,
123,122,122,122,122,122,122,122,
122,122,122,122,122,122,122,122,
122,122,122,122,123,122,125,124,
124,124,124,124,124,124,124,124,
124,124,124,124,124,124,124,124,
124,124,125,124,127,126,126,126,
126,126,126,126,126,126,126,126,
126,126,126,126,126,126,126,126,
127,126,129,129,128,128,128,128,
129,128,128,128,130,128,128,128,
128,128,128,128,128,128,128,128,
128,128,128,129,128,128,128,128,
128,128,128,129,128,128,128,128,
131,128,128,128,132,128,128,128,
128,128,128,128,128,128,128,128,
128,128,128,129,128,134,133,133,
133,42,42,42,42,42,42,42,
42,42,42,133,135,44,44,44,
135,44,44,44,44,44,44,44,
44,44,135,135,44,44,44,135,
135,44,44,44,44,44,44,44,
44,44,44,44,135,44,44,44,
135,44,44,44,44,44,44,44,
44,44,44,135,44,44,44,135,
44,136,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,44,44,44,44,44,44,44,
44,136,44,137,137,137,137,137,
137,137,137,137,137,137,137,137,
137,137,137,137,137,137,137,137,
137,137,137,137,137,137,137,137,
137,138,138,138,138,138,138,138,
138,138,138,138,138,138,138,138,
138,139,139,139,139,139,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,140,49,141,
49,140,140,140,140,49,142,140,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
140,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,143,144,145,146,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,140,140,140,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
49,49,49,49,49,49,49,49,
147,50,50,50,50,50,50,50,
50,50,50,50,50,50,50,50,
50,50,50,50,50,50,50,50,
50,50,50,50,50,50,50,50,
50,50,50,50,50,50,50,50,
50,50,50,50,50,50,50,50,
50,50,50,50,50,50,50,50,
50,50,50,50,50,50,50,50,
50,147,148,148,148,148,148,148,
148,148,148,148,148,148,148,148,
148,148,148,148,148,148,148,148,
148,148,148,148,148,148,148,148,
148,148,148,148,148,148,148,148,
148,148,148,148,148,148,148,148,
148,148,148,148,148,148,148,148,
148,148,148,148,148,148,148,148,
148,148,147,149,147,151,150,150,
150,150,150,150,150,150,150,150,
150,150,150,150,150,150,150,150,
150,150,150,150,150,150,150,150,
150,150,150,150,150,150,150,150,
150,150,150,150,150,150,150,150,
150,150,150,150,150,150,150,150,
150,150,150,150,152,150,54,154,
156,156,156,156,156,156,156,156,
155,155,155,155,155,155,155,155,
155,155,155,157,157,155,155,155,
157,155,155,155,155,157,155,155,
157,155,155,157,155,155,155,157,
155,155,155,157,157,157,155,155,
155,157,157,157,157,157,157,155,
157,155,155,155,155,155,157,155,
157,155,157,157,157,157,157,157,
157,155,159,159,159,159,159,159,
159,159,158,160,160,160,160,160,
160,160,160,158,161,161,161,161,
161,161,161,161,161,161,161,161,
161,161,161,161,161,161,161,161,
161,161,161,161,161,161,161,161,
161,161,162,162,162,162,162,162,
162,162,162,162,162,162,162,162,
162,162,163,163,163,163,163,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,164,59,
59,59,164,164,164,164,59,59,
164,59,165,166,166,166,166,166,
166,166,167,167,59,59,59,59,
59,164,59,44,44,168,169,59,
59,44,169,59,59,44,59,170,
59,59,171,59,169,169,59,59,
59,169,169,59,44,164,164,164,
164,59,59,172,172,61,169,172,
172,59,169,59,59,59,59,59,
172,59,171,59,172,169,172,173,
172,169,174,59,44,164,164,164,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,59,59,59,59,59,59,59,
59,175,60,60,60,60,60,60,
60,60,60,60,60,60,60,60,
60,60,60,60,60,60,60,60,
60,60,60,60,60,60,60,60,
60,60,60,60,60,60,60,60,
60,60,60,60,60,60,60,60,
60,60,60,60,60,60,60,60,
60,60,60,60,60,60,60,60,
60,60,175,176,176,176,176,176,
176,176,176,176,176,176,176,176,
176,176,176,176,176,176,176,176,
176,176,176,176,176,176,176,176,
176,176,176,176,176,176,176,176,
176,176,176,176,176,176,176,176,
176,176,176,176,176,176,176,176,
176,176,176,176,176,176,176,176,
176,176,176,175,178,178,178,178,
178,178,178,178,177,180,180,180,
180,180,180,180,180,179,182,182,
182,182,182,182,182,182,182,182,
181,184,62,186,185,62,188,67,
67,67,67,67,67,67,67,67,
67,67,67,67,67,67,67,67,
67,67,67,67,67,67,67,67,
67,67,67,67,67,67,189,67,
191,190,67,70,67,193,193,193,
193,193,193,193,193,193,193,192,
192,192,192,192,192,192,193,193,
193,193,193,193,192,192,192,192,
192,192,192,192,192,192,192,192,
192,192,192,192,192,192,192,192,
192,192,192,192,192,192,193,193,
193,193,193,193,192,195,194,194,
194,194,194,196,194,194,197,197,
197,197,197,197,197,197,197,197,
194,194,198,194,86,85,85,85,
85,85,199,85,85,199,199,199,
199,199,199,199,199,199,199,85,
88,88,88,88,88,88,88,88,
88,88,199,87,199,199,199,199,
199,199,88,88,88,88,88,88,
88,88,88,88,199,199,89,89,
89,89,89,89,89,89,89,89,
89,199,89,89,199,199,199,199,
199,199,199,199,199,199,89,89,
89,89,86,89,0
]

class << self
	attr_accessor :_re_scanner_trans_targs
	private :_re_scanner_trans_targs, :_re_scanner_trans_targs=
end
self._re_scanner_trans_targs = [
71,72,1,2,71,4,71,6,
71,8,71,81,71,10,16,11,
71,12,13,14,15,17,18,19,
20,21,23,29,24,71,25,26,
27,28,30,31,32,33,34,71,
36,71,37,39,0,40,41,88,
89,89,42,89,89,89,45,46,
89,89,99,99,47,50,99,106,
99,108,53,99,109,99,111,56,
59,57,58,99,60,61,62,63,
64,65,99,113,114,67,68,114,
69,70,3,73,74,75,76,77,
71,78,71,82,83,71,84,71,
85,71,71,86,71,71,71,71,
71,71,79,71,80,5,71,7,
71,71,71,71,71,71,71,71,
71,71,71,9,22,71,35,87,
38,90,91,92,89,93,94,95,
89,89,89,89,43,89,89,44,
89,89,89,96,97,96,96,98,
96,100,101,102,99,103,103,105,
49,99,52,99,99,55,66,99,
48,99,104,99,99,99,99,99,
107,99,51,99,110,112,99,54,
99,99,114,115,116,117,118,114
]

class << self
	attr_accessor :_re_scanner_trans_actions
	private :_re_scanner_trans_actions, :_re_scanner_trans_actions=
end
self._re_scanner_trans_actions = [
1,2,0,0,3,0,4,0,
5,0,6,7,8,0,0,0,
9,0,0,0,0,0,0,0,
0,0,0,0,0,10,0,0,
0,0,0,0,0,0,0,11,
0,12,0,0,0,0,0,14,
15,16,0,17,18,19,0,0,
20,21,22,23,0,0,25,0,
26,0,0,27,0,28,0,0,
0,0,0,29,0,0,0,0,
0,0,30,0,31,0,0,32,
0,0,0,0,0,0,0,0,
35,36,37,0,0,38,0,39,
40,41,42,40,43,44,45,46,
47,48,49,50,0,0,51,0,
52,53,54,55,56,57,58,59,
60,61,62,0,0,63,0,65,
0,0,40,40,66,0,40,67,
68,69,70,71,0,72,73,0,
74,75,76,77,0,78,79,0,
80,0,40,40,81,82,83,0,
0,84,0,85,86,0,0,87,
0,88,0,89,90,91,92,93,
40,94,0,95,40,0,96,0,
97,98,99,40,40,40,40,100
]

class << self
	attr_accessor :_re_scanner_to_state_actions
	private :_re_scanner_to_state_actions, :_re_scanner_to_state_actions=
end
self._re_scanner_to_state_actions = [
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,33,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,64,
64,64,0,0,0,0,0,0,
64,0,0,64,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,64,0,0,0,0
]

class << self
	attr_accessor :_re_scanner_from_state_actions
	private :_re_scanner_from_state_actions, :_re_scanner_from_state_actions=
end
self._re_scanner_from_state_actions = [
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,34,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,34,
34,34,0,0,0,0,0,0,
34,0,0,34,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,34,0,0,0,0
]

class << self
	attr_accessor :_re_scanner_eof_actions
	private :_re_scanner_eof_actions, :_re_scanner_eof_actions=
end
self._re_scanner_eof_actions = [
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,13,13,
13,13,0,0,0,0,0,0,
0,24,24,0,24,24,0,24,
24,24,24,24,24,24,24,24,
24,24,24,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,
0,24,0,0,0,0,0,0,
0,0,0,24,0,0,0,0,
0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0
]

class << self
	attr_accessor :_re_scanner_eof_trans
	private :_re_scanner_eof_trans, :_re_scanner_eof_trans=
end
self._re_scanner_eof_trans = [
0,1,1,1,5,5,5,5,
1,13,13,13,13,13,13,13,
13,13,13,13,13,13,13,13,
13,13,13,13,13,13,13,13,
13,13,13,40,40,40,0,0,
0,0,49,49,52,54,54,59,
59,0,0,65,0,0,70,0,
0,0,0,0,0,0,0,0,
0,0,0,85,85,85,85,0,
110,110,111,111,110,112,114,116,
116,122,123,125,127,129,134,0,
0,0,148,148,148,148,151,154,
0,159,159,0,176,176,176,178,
180,182,184,184,184,188,188,188,
188,193,0,200,200,200,200
]

class << self
	attr_accessor :re_scanner_start
end
self.re_scanner_start = 71;
class << self
	attr_accessor :re_scanner_first_final
end
self.re_scanner_first_final = 71;
class << self
	attr_accessor :re_scanner_error
end
self.re_scanner_error = 0;

class << self
	attr_accessor :re_scanner_en_char_type
end
self.re_scanner_en_char_type = 87;
class << self
	attr_accessor :re_scanner_en_unicode_property
end
self.re_scanner_en_unicode_property = 88;
class << self
	attr_accessor :re_scanner_en_character_set
end
self.re_scanner_en_character_set = 89;
class << self
	attr_accessor :re_scanner_en_set_escape_sequence
end
self.re_scanner_en_set_escape_sequence = 96;
class << self
	attr_accessor :re_scanner_en_escape_sequence
end
self.re_scanner_en_escape_sequence = 99;
class << self
	attr_accessor :re_scanner_en_conditional_expression
end
self.re_scanner_en_conditional_expression = 114;
class << self
	attr_accessor :re_scanner_en_main
end
self.re_scanner_en_main = 71;

begin
	p ||= 0
	pe ||= data.length
	cs = re_scanner_start
	top = 0
	ts = nil
	te = nil
	act = 0
end

begin
	testEof = false
	_slen, _trans, _keys, _inds, _acts, _nacts = nil
	_goto_level = 0
	_resume = 10
	_eof_trans = 15
	_again = 20
	_test_eof = 30
	_out = 40
	while true
	if _goto_level <= 0
	if p == pe
		_goto_level = _test_eof
		next
	end
	if cs == 0
		_goto_level = _out
		next
	end
	end
	if _goto_level <= _resume
	case _re_scanner_from_state_actions[cs]
	when 34 then
		begin
ts = p
		end
	end
	_keys = cs << 1
	_inds = _re_scanner_index_offsets[cs]
	_slen = _re_scanner_key_spans[cs]
	_wide = data[p].ord
	_trans = if (   _slen > 0 &&
			_re_scanner_trans_keys[_keys] <= _wide &&
			_wide <= _re_scanner_trans_keys[_keys + 1]
		    ) then
			_re_scanner_indicies[ _inds + _wide - _re_scanner_trans_keys[_keys] ]
		 else
			_re_scanner_indicies[ _inds + _slen ]
		 end
	end
	if _goto_level <= _eof_trans
	cs = _re_scanner_trans_targs[_trans]
	if _re_scanner_trans_actions[_trans] != 0
	case _re_scanner_trans_actions[_trans]
	when 36 then
		begin
 self.group_depth = group_depth + 1 		end
	when 40 then
		begin
te = p+1
		end
	when 65 then
		begin
te = p+1
 begin
      case text = copy(data, ts-1,te)
      when '\d'; emit(:type, :digit,      text)
      when '\D'; emit(:type, :nondigit,   text)
      when '\h'; emit(:type, :hex,        text)
      when '\H'; emit(:type, :nonhex,     text)
      when '\s'; emit(:type, :space,      text)
      when '\S'; emit(:type, :nonspace,   text)
      when '\w'; emit(:type, :word,       text)
      when '\W'; emit(:type, :nonword,    text)
      when '\R'; emit(:type, :linebreak,  text)
      when '\X'; emit(:type, :xgrapheme,  text)
      end
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 14 then
		begin
te = p+1
 begin
      text = copy(data, ts-1,te)
      type = (text[1] == 'P') ^ (text[3] == '^') ? :nonproperty : :property

      name = text[3..-2].gsub(/[\^\s_\-]/, '').downcase

      token = self.class.short_prop_map[name] || self.class.long_prop_map[name]
      raise ValidationError.for(:property, name) unless token

      self.emit(type, token.to_sym, text)

      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 18 then
		begin
te = p+1
 begin  # special case, emits two tokens
      emit(:literal, :literal, '-')
      emit(:set, :intersection, '&&')
     end
		end
	when 70 then
		begin
te = p+1
 begin
      if prev_token[1] == :open
        emit(:set, :negate, '^')
      else
        emit(:literal, :literal, '^')
      end
     end
		end
	when 72 then
		begin
te = p+1
 begin
      emit(:set, :intersection, '&&')
     end
		end
	when 68 then
		begin
te = p+1
 begin
      	begin
		stack[top] = cs
		top+= 1
		cs = 96
		_goto_level = _again
		next
	end

     end
		end
	when 66 then
		begin
te = p+1
 begin
      emit(:literal, :literal, copy(data, ts, te))
     end
		end
	when 16 then
		begin
te = p+1
 begin
      text = copy(data, ts, te)
      emit(:literal, :literal, text)
     end
		end
	when 73 then
		begin
te = p
p = p - 1; begin
      # ranges cant start with the opening bracket, a subset, or
      # intersection/negation/range operators
      if prev_token[0] == :set
        emit(:literal, :literal, '-')
      else
        emit(:set, :range, '-')
      end
     end
		end
	when 76 then
		begin
te = p
p = p - 1; begin
      emit(:set, :open, '[')
      	begin
		stack[top] = cs
		top+= 1
		cs = 89
		_goto_level = _again
		next
	end

     end
		end
	when 71 then
		begin
te = p
p = p - 1; begin
      text = copy(data, ts, te)
      emit(:literal, :literal, text)
     end
		end
	when 17 then
		begin
 begin p = ((te))-1; end
 begin
      # ranges cant start with the opening bracket, a subset, or
      # intersection/negation/range operators
      if prev_token[0] == :set
        emit(:literal, :literal, '-')
      else
        emit(:set, :range, '-')
      end
     end
		end
	when 20 then
		begin
 begin p = ((te))-1; end
 begin
      emit(:set, :open, '[')
      	begin
		stack[top] = cs
		top+= 1
		cs = 89
		_goto_level = _again
		next
	end

     end
		end
	when 15 then
		begin
 begin p = ((te))-1; end
 begin
      text = copy(data, ts, te)
      emit(:literal, :literal, text)
     end
		end
	when 80 then
		begin
te = p+1
 begin
      emit(:escape, :octal, copy(data, ts-1,te))
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 78 then
		begin
te = p+1
 begin
      p = p - 1;
      cs = 89;
      	begin
		stack[top] = cs
		top+= 1
		cs = 99
		_goto_level = _again
		next
	end

     end
		end
	when 77 then
		begin
te = p+1
 begin
      emit(:escape, :literal, copy(data, ts-1,te))
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 79 then
		begin
te = p
p = p - 1; begin
      emit(:escape, :octal, copy(data, ts-1,te))
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 90 then
		begin
te = p+1
 begin
      emit(:escape, :octal, copy(data, ts-1,te))
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 92 then
		begin
te = p+1
 begin  # special case, emits two tokens
      text = copy(data, ts-1,te)
      emit(:escape, :literal, text[0,2])
      emit(:literal, :literal, text[2])
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 81 then
		begin
te = p+1
 begin
      case text = copy(data, ts-1,te)
      when '\.';  emit(:escape, :dot,               text)
      when '\|';  emit(:escape, :alternation,       text)
      when '\^';  emit(:escape, :bol,               text)
      when '\$';  emit(:escape, :eol,               text)
      when '\?';  emit(:escape, :zero_or_one,       text)
      when '\*';  emit(:escape, :zero_or_more,      text)
      when '\+';  emit(:escape, :one_or_more,       text)
      when '\(';  emit(:escape, :group_open,        text)
      when '\)';  emit(:escape, :group_close,       text)
      when '\{';  emit(:escape, :interval_open,     text)
      when '\}';  emit(:escape, :interval_close,    text)
      when '\[';  emit(:escape, :set_open,          text)
      when '\]';  emit(:escape, :set_close,         text)
      when "\\\\";
        emit(:escape, :backslash, text)
      end
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 86 then
		begin
te = p+1
 begin
      # \b is emitted as backspace only when inside a character set, otherwise
      # it is a word boundary anchor. A syntax might "normalize" it if needed.
      case text = copy(data, ts-1,te)
      when '\a'; emit(:escape, :bell,           text)
      when '\b'; emit(:escape, :backspace,      text)
      when '\e'; emit(:escape, :escape,         text)
      when '\f'; emit(:escape, :form_feed,      text)
      when '\n'; emit(:escape, :newline,        text)
      when '\r'; emit(:escape, :carriage,       text)
      when '\t'; emit(:escape, :tab,            text)
      when '\v'; emit(:escape, :vertical_tab,   text)
      end
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 29 then
		begin
te = p+1
 begin
      text = copy(data, ts-1,te)
      if text[2] == '{'
        emit(:escape, :codepoint_list, text)
      else
        emit(:escape, :codepoint,      text)
      end
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 98 then
		begin
te = p+1
 begin
      emit(:escape, :hex, copy(data, ts-1,te))
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 25 then
		begin
te = p+1
 begin
      emit_meta_control_sequence(data, ts, te, :control)
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 27 then
		begin
te = p+1
 begin
      emit_meta_control_sequence(data, ts, te, :meta_sequence)
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 84 then
		begin
te = p+1
 begin
      p = p - 1;
      cs = ((in_set? ? 89 : 71));
      	begin
		stack[top] = cs
		top+= 1
		cs = 87
		_goto_level = _again
		next
	end

     end
		end
	when 85 then
		begin
te = p+1
 begin
      p = p - 1;
      cs = ((in_set? ? 89 : 71));
      	begin
		stack[top] = cs
		top+= 1
		cs = 88
		_goto_level = _again
		next
	end

     end
		end
	when 23 then
		begin
te = p+1
 begin
      emit(:escape, :literal, copy(data, ts-1,te))
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 91 then
		begin
te = p
p = p - 1; begin
      text = copy(data, ts-1,te)
      emit(:backref, :number, text)
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 89 then
		begin
te = p
p = p - 1; begin
      emit(:escape, :octal, copy(data, ts-1,te))
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 97 then
		begin
te = p
p = p - 1; begin
      emit(:escape, :hex, copy(data, ts-1,te))
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 94 then
		begin
te = p
p = p - 1; begin
      emit_meta_control_sequence(data, ts, te, :control)
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 96 then
		begin
te = p
p = p - 1; begin
      emit_meta_control_sequence(data, ts, te, :meta_sequence)
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 87 then
		begin
te = p
p = p - 1; begin
      emit(:escape, :literal, copy(data, ts-1,te))
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 22 then
		begin
 begin p = ((te))-1; end
 begin
      emit(:escape, :literal, copy(data, ts-1,te))
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 88 then
		begin
	case act
	when 17 then
	begin begin p = ((te))-1; end

      text = copy(data, ts-1,te)
      emit(:backref, :number, text)
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

    end
	when 18 then
	begin begin p = ((te))-1; end

      emit(:escape, :octal, copy(data, ts-1,te))
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

    end
end
			end
	when 32 then
		begin
te = p+1
 begin
      text = copy(data, ts, te-1)
      text =~ /[^0]/ or raise ValidationError.for(:backref, 'condition', 'invalid ref ID')
      emit(:conditional, :condition, text)
      emit(:conditional, :condition_close, ')')
     end
		end
	when 99 then
		begin
te = p+1
 begin
      p = p - 1;
      	begin
		stack[top] = cs
		top+= 1
		cs = 71
		_goto_level = _again
		next
	end

     end
		end
	when 100 then
		begin
te = p
p = p - 1; begin
      p = p - 1;
      	begin
		stack[top] = cs
		top+= 1
		cs = 71
		_goto_level = _again
		next
	end

     end
		end
	when 31 then
		begin
 begin p = ((te))-1; end
 begin
      p = p - 1;
      	begin
		stack[top] = cs
		top+= 1
		cs = 71
		_goto_level = _again
		next
	end

     end
		end
	when 38 then
		begin
te = p+1
 begin
      emit(:meta, :dot, copy(data, ts, te))
     end
		end
	when 43 then
		begin
te = p+1
 begin
      if conditional_stack.last == group_depth
        emit(:conditional, :separator, copy(data, ts, te))
      else
        emit(:meta, :alternation, copy(data, ts, te))
      end
     end
		end
	when 42 then
		begin
te = p+1
 begin
      emit(:anchor, :bol, copy(data, ts, te))
     end
		end
	when 35 then
		begin
te = p+1
 begin
      emit(:anchor, :eol, copy(data, ts, te))
     end
		end
	when 62 then
		begin
te = p+1
 begin
      emit(:keep, :mark, copy(data, ts, te))
     end
		end
	when 61 then
		begin
te = p+1
 begin
      case text = copy(data, ts, te)
      when '\A';  emit(:anchor, :bos,                text)
      when '\z';  emit(:anchor, :eos,                text)
      when '\Z';  emit(:anchor, :eos_ob_eol,         text)
      when '\b';  emit(:anchor, :word_boundary,      text)
      when '\B';  emit(:anchor, :nonword_boundary,   text)
      when '\G';  emit(:anchor, :match_start,        text)
      end
     end
		end
	when 41 then
		begin
te = p+1
 begin
      append_literal(data, ts, te)
     end
		end
	when 51 then
		begin
te = p+1
 begin
      text = copy(data, ts, te)

      conditional_stack << group_depth

      emit(:conditional, :open, text[0..-2])
      emit(:conditional, :condition_open, '(')
      	begin
		stack[top] = cs
		top+= 1
		cs = 114
		_goto_level = _again
		next
	end

     end
		end
	when 52 then
		begin
te = p+1
 begin
      text = copy(data, ts, te)
      if text[2..-1] =~ /([^\-mixdau:]|^$)|-.*([dau])/
        raise ValidationError.for(:group_option, $1 || "-#{$2}", text)
      end
      emit_options(text)
     end
		end
	when 6 then
		begin
te = p+1
 begin
      case text = copy(data, ts, te)
      when '(?=';  emit(:assertion, :lookahead,    text)
      when '(?!';  emit(:assertion, :nlookahead,   text)
      when '(?<='; emit(:assertion, :lookbehind,   text)
      when '(?<!'; emit(:assertion, :nlookbehind,  text)
      end
     end
		end
	when 5 then
		begin
te = p+1
 begin
      case text = copy(data, ts, te)
      when '(?:';  emit(:group, :passive,      text)
      when '(?>';  emit(:group, :atomic,       text)
      when '(?~';  emit(:group, :absence,      text)

      when /^\(\?(?:<>|'')/
        raise ValidationError.for(:group, 'named group', 'name is empty')

      when /^\(\?<[^>]+>/
        emit(:group, :named_ab,  text)

      when /^\(\?'[^']+'/
        emit(:group, :named_sq,  text)

      end
     end
		end
	when 10 then
		begin
te = p+1
 begin
      case text = copy(data, ts, te)
      when /^\\k(.)[^0-9\-][^+\-]*['>]$/
        emit(:backref, $1 == '<' ? :name_ref_ab : :name_ref_sq, text)
      when /^\\k(.)0*[1-9]\d*['>]$/
        emit(:backref, $1 == '<' ? :number_ref_ab : :number_ref_sq, text)
      when /^\\k(.)-0*[1-9]\d*['>]$/
        emit(:backref, $1 == '<' ? :number_rel_ref_ab : :number_rel_ref_sq, text)
      when /^\\k(.)[^0-9\-].*[+\-]\d+['>]$/
        emit(:backref, $1 == '<' ? :name_recursion_ref_ab : :name_recursion_ref_sq, text)
      when /^\\k(.)-?0*[1-9]\d*[+\-]\d+['>]$/
        emit(:backref, $1 == '<' ? :number_recursion_ref_ab : :number_recursion_ref_sq, text)
      else
        raise ValidationError.for(:backref, 'backreference', 'invalid ref ID')
      end
     end
		end
	when 9 then
		begin
te = p+1
 begin
      case text = copy(data, ts, te)
      when /^\\g(.)[^0-9+\-].*['>]$/
        emit(:backref, $1 == '<' ? :name_call_ab : :name_call_sq, text)
      when /^\\g(.)(?:0|0*[1-9]\d*)['>]$/
        emit(:backref, $1 == '<' ? :number_call_ab : :number_call_sq, text)
      when /^\\g(.)[+-]0*[1-9]\d*/
        emit(:backref, $1 == '<' ? :number_rel_call_ab : :number_rel_call_sq, text)
      else
        raise ValidationError.for(:backref, 'subexpression call', 'invalid ref ID')
      end
     end
		end
	when 59 then
		begin
te = p+1
 begin
      case text = copy(data, ts, te)
      when '?' ;  emit(:quantifier, :zero_or_one,            text)
      when '??';  emit(:quantifier, :zero_or_one_reluctant,  text)
      when '?+';  emit(:quantifier, :zero_or_one_possessive, text)
      end
     end
		end
	when 55 then
		begin
te = p+1
 begin
      case text = copy(data, ts, te)
      when '*' ;  emit(:quantifier, :zero_or_more,            text)
      when '*?';  emit(:quantifier, :zero_or_more_reluctant,  text)
      when '*+';  emit(:quantifier, :zero_or_more_possessive, text)
      end
     end
		end
	when 57 then
		begin
te = p+1
 begin
      case text = copy(data, ts, te)
      when '+' ;  emit(:quantifier, :one_or_more,            text)
      when '+?';  emit(:quantifier, :one_or_more_reluctant,  text)
      when '++';  emit(:quantifier, :one_or_more_possessive, text)
      end
     end
		end
	when 12 then
		begin
te = p+1
 begin
      emit(:quantifier, :interval, copy(data, ts, te))
     end
		end
	when 47 then
		begin
te = p+1
 begin
      if free_spacing
        emit(:free_space, :comment, copy(data, ts, te))
      else
        # consume only the pound sign (#) and backtrack to do regular scanning
        append_literal(data, ts, ts + 1)
         begin p = (( ts + 1))-1; end

      end
     end
		end
	when 50 then
		begin
te = p
p = p - 1; begin
      text = copy(data, ts, te)
      if text[2..-1] =~ /([^\-mixdau:]|^$)|-.*([dau])/
        raise ValidationError.for(:group_option, $1 || "-#{$2}", text)
      end
      emit_options(text)
     end
		end
	when 53 then
		begin
te = p
p = p - 1; begin
      case text = copy(data, ts, te)
      when '(?=';  emit(:assertion, :lookahead,    text)
      when '(?!';  emit(:assertion, :nlookahead,   text)
      when '(?<='; emit(:assertion, :lookbehind,   text)
      when '(?<!'; emit(:assertion, :nlookbehind,  text)
      end
     end
		end
	when 48 then
		begin
te = p
p = p - 1; begin
      text = copy(data, ts, te)
      emit(:group, :capture, text)
     end
		end
	when 58 then
		begin
te = p
p = p - 1; begin
      case text = copy(data, ts, te)
      when '?' ;  emit(:quantifier, :zero_or_one,            text)
      when '??';  emit(:quantifier, :zero_or_one_reluctant,  text)
      when '?+';  emit(:quantifier, :zero_or_one_possessive, text)
      end
     end
		end
	when 54 then
		begin
te = p
p = p - 1; begin
      case text = copy(data, ts, te)
      when '*' ;  emit(:quantifier, :zero_or_more,            text)
      when '*?';  emit(:quantifier, :zero_or_more_reluctant,  text)
      when '*+';  emit(:quantifier, :zero_or_more_possessive, text)
      end
     end
		end
	when 56 then
		begin
te = p
p = p - 1; begin
      case text = copy(data, ts, te)
      when '+' ;  emit(:quantifier, :one_or_more,            text)
      when '+?';  emit(:quantifier, :one_or_more_reluctant,  text)
      when '++';  emit(:quantifier, :one_or_more_possessive, text)
      end
     end
		end
	when 63 then
		begin
te = p
p = p - 1; begin
      append_literal(data, ts, te)
     end
		end
	when 60 then
		begin
te = p
p = p - 1; begin
      	begin
		stack[top] = cs
		top+= 1
		cs = 99
		_goto_level = _again
		next
	end

     end
		end
	when 46 then
		begin
te = p
p = p - 1; begin
      if free_spacing
        emit(:free_space, :comment, copy(data, ts, te))
      else
        # consume only the pound sign (#) and backtrack to do regular scanning
        append_literal(data, ts, ts + 1)
         begin p = (( ts + 1))-1; end

      end
     end
		end
	when 45 then
		begin
te = p
p = p - 1; begin
      if free_spacing
        emit(:free_space, :whitespace, copy(data, ts, te))
      else
        append_literal(data, ts, te)
      end
     end
		end
	when 44 then
		begin
te = p
p = p - 1; begin
      append_literal(data, ts, te)
     end
		end
	when 3 then
		begin
 begin p = ((te))-1; end
 begin
      text = copy(data, ts, te)
      if text[2..-1] =~ /([^\-mixdau:]|^$)|-.*([dau])/
        raise ValidationError.for(:group_option, $1 || "-#{$2}", text)
      end
      emit_options(text)
     end
		end
	when 11 then
		begin
 begin p = ((te))-1; end
 begin
      append_literal(data, ts, te)
     end
		end
	when 8 then
		begin
 begin p = ((te))-1; end
 begin
      	begin
		stack[top] = cs
		top+= 1
		cs = 99
		_goto_level = _again
		next
	end

     end
		end
	when 1 then
		begin
	case act
	when 0 then
	begin	begin
		cs = 0
		_goto_level = _again
		next
	end
end
	when 42 then
	begin begin p = ((te))-1; end

      text = copy(data, ts, te)
      if text[2..-1] =~ /([^\-mixdau:]|^$)|-.*([dau])/
        raise ValidationError.for(:group_option, $1 || "-#{$2}", text)
      end
      emit_options(text)
    end
	when 43 then
	begin begin p = ((te))-1; end

      case text = copy(data, ts, te)
      when '(?=';  emit(:assertion, :lookahead,    text)
      when '(?!';  emit(:assertion, :nlookahead,   text)
      when '(?<='; emit(:assertion, :lookbehind,   text)
      when '(?<!'; emit(:assertion, :nlookbehind,  text)
      end
    end
	when 57 then
	begin begin p = ((te))-1; end

      append_literal(data, ts, te)
    end
end
			end
	when 75 then
		begin

    text = copy(data, ts ? ts-1 : 0,-1)
    raise PrematureEndError.new(text)
  		end
		begin
te = p
p = p - 1; begin
      emit(:set, :open, '[')
      	begin
		stack[top] = cs
		top+= 1
		cs = 89
		_goto_level = _again
		next
	end

     end
		end
	when 19 then
		begin

    text = copy(data, ts ? ts-1 : 0,-1)
    raise PrematureEndError.new(text)
  		end
		begin
 begin p = ((te))-1; end
 begin
      emit(:set, :open, '[')
      	begin
		stack[top] = cs
		top+= 1
		cs = 89
		_goto_level = _again
		next
	end

     end
		end
	when 93 then
		begin

    text = copy(data, ts ? ts-1 : 0,-1)
    raise PrematureEndError.new(text)
  		end
		begin
te = p
p = p - 1; begin
      emit_meta_control_sequence(data, ts, te, :control)
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 95 then
		begin

    text = copy(data, ts ? ts-1 : 0,-1)
    raise PrematureEndError.new(text)
  		end
		begin
te = p
p = p - 1; begin
      emit_meta_control_sequence(data, ts, te, :meta_sequence)
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 26 then
		begin

    text = copy(data, ts ? ts-1 : 0,-1)
    raise PrematureEndError.new(text)
  		end
		begin
 begin p = ((te))-1; end
 begin
      emit_meta_control_sequence(data, ts, te, :control)
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 28 then
		begin

    text = copy(data, ts ? ts-1 : 0,-1)
    raise PrematureEndError.new(text)
  		end
		begin
 begin p = ((te))-1; end
 begin
      emit_meta_control_sequence(data, ts, te, :meta_sequence)
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 30 then
		begin

    text = copy(data, ts ? ts-1 : 0,-1)
    raise ValidationError.for(:sequence, 'sequence', text)
  		end
		begin
te = p+1
 begin
      	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

     end
		end
	when 4 then
		begin
 self.group_depth = group_depth - 1 		end
		begin
te = p+1
 begin
      emit(:group, :comment, copy(data, ts, te))
     end
		end
	when 37 then
		begin
 self.group_depth = group_depth - 1 		end
		begin
te = p+1
 begin
      if conditional_stack.last == group_depth + 1
        conditional_stack.pop
        emit(:conditional, :close, ')')
      elsif group_depth >= 0
        if spacing_stack.length > 1 &&
           spacing_stack.last[:depth] == group_depth + 1
          spacing_stack.pop
          self.free_spacing = spacing_stack.last[:free_spacing]
        end

        emit(:group, :close, ')')
      else
        raise ValidationError.for(:group, 'group', 'unmatched close parenthesis')
      end
     end
		end
	when 39 then
		begin
 self.set_depth   = set_depth   + 1 		end
		begin
te = p+1
 begin
      emit(:set, :open, copy(data, ts, te))
      	begin
		stack[top] = cs
		top+= 1
		cs = 89
		_goto_level = _again
		next
	end

     end
		end
	when 69 then
		begin
 self.set_depth   = set_depth   - 1 		end
		begin
te = p+1
 begin
      emit(:set, :close, copy(data, ts, te))
      if in_set?
        	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

      else
        	begin
		cs = 71
		_goto_level = _again
		next
	end

      end
     end
		end
	when 74 then
		begin
 self.set_depth   = set_depth   - 1 		end
		begin
te = p+1
 begin  # special case, emits two tokens
      emit(:literal, :literal, '-')
      emit(:set, :close, ']')
      if in_set?
        	begin
		top -= 1
		cs = stack[top]
		_goto_level = _again
		next
	end

      else
        	begin
		cs = 71
		_goto_level = _again
		next
	end

      end
     end
		end
	when 21 then
		begin
 self.set_depth   = set_depth   - 1 		end
		begin
te = p+1
 begin
      text = copy(data, ts, te)

      type = :posixclass
      class_name = text[2..-3]
      if class_name[0] == '^'
        class_name = class_name[1..-1]
        type = :nonposixclass
      end

      unless self.class.posix_classes.include?(class_name)
        raise ValidationError.for(:posix_class, text)
      end

      emit(type, class_name.to_sym, text)
     end
		end
	when 67 then
		begin
te = p+1
		end
		begin
 self.set_depth   = set_depth   + 1 		end
	when 83 then
		begin
te = p+1
		end
		begin
act = 17;		end
	when 82 then
		begin
te = p+1
		end
		begin
act = 18;		end
	when 49 then
		begin
te = p+1
		end
		begin
act = 42;		end
	when 7 then
		begin
te = p+1
		end
		begin
act = 43;		end
	when 2 then
		begin
te = p+1
		end
		begin
act = 57;		end
	end
	end
	end
	if _goto_level <= _again
	case _re_scanner_to_state_actions[cs]
	when 64 then
		begin
ts = nil;		end
	when 33 then
		begin
ts = nil;		end
		begin
act = 0
		end
	end

	if cs == 0
		_goto_level = _out
		next
	end
	p += 1
	if p != pe
		_goto_level = _resume
		next
	end
	end
	if _goto_level <= _test_eof
	if p == eof
	if _re_scanner_eof_trans[cs] > 0
		_trans = _re_scanner_eof_trans[cs] - 1;
		_goto_level = _eof_trans
		next;
	end
	  case _re_scanner_eof_actions[cs]
	when 13 then
		begin

    raise PrematureEndError.new('unicode property')
  		end
	when 24 then
		begin

    text = copy(data, ts ? ts-1 : 0,-1)
    raise PrematureEndError.new(text)
  		end
	  end
	end

	end
	if _goto_level <= _out
		break
	end
end
	end

    # to avoid "warning: assigned but unused variable - testEof"
    testEof = testEof

    if cs == re_scanner_error
      text = copy(data, ts ? ts-1 : 0,-1)
      raise ScannerError.new("Scan error at '#{text}'")
    end

    raise PrematureEndError.new("(missing group closing paranthesis) "+
          "[#{group_depth}]") if in_group?
    raise PrematureEndError.new("(missing set closing bracket) "+
          "[#{set_depth}]") if in_set?

    # when the entire expression is a literal run
    emit_literal if literal_run

    tokens
  end

  # lazy-load property maps when first needed
  def self.short_prop_map
    @short_prop_map ||= parse_prop_map('short')
  end

  def self.long_prop_map
    @long_prop_map ||= parse_prop_map('long')
  end

  def self.parse_prop_map(name)
    File.read("#{__dir__}/scanner/properties/#{name}.csv").scan(/(.+),(.+)/).to_h
  end

  def self.posix_classes
    %w[alnum alpha ascii blank cntrl digit graph
       lower print punct space upper word xdigit]
  end

  # Emits an array with the details of the scanned pattern
  def emit(type, token, text)
    #puts "EMIT: type: #{type}, token: #{token}, text: #{text}, ts: #{ts}, te: #{te}"

    emit_literal if literal_run

    # Ragel runs with byte-based indices (ts, te). These are of little value to
    # end-users, so we keep track of char-based indices and emit those instead.
    ts_char_pos = char_pos
    te_char_pos = char_pos + text.length

    tok = [type, token, text, ts_char_pos, te_char_pos]

    self.prev_token = tok

    self.char_pos = te_char_pos

    if block
      block.call type, token, text, ts_char_pos, te_char_pos
      # TODO: in v3.0.0,remove `collect_tokens:` kwarg and only collect if no block given
      tokens << tok if collect_tokens
    elsif collect_tokens
      tokens << tok
    end
  end

  attr_accessor :literal_run # only public for #||= to work on ruby <= 2.5

  private

  attr_accessor :block,
                :collect_tokens, :tokens, :prev_token,
                :free_spacing, :spacing_stack,
                :group_depth, :set_depth, :conditional_stack,
                :char_pos

  def free_spacing?(input_object, options)
    if options && !input_object.is_a?(String)
      raise ArgumentError, 'options cannot be supplied unless scanning a String'
    end

    options = input_object.options if input_object.is_a?(::Regexp)

    return false unless options

    options & Regexp::EXTENDED != 0
  end

  def in_group?
    group_depth > 0
  end

  def in_set?
    set_depth > 0
  end

  # Copy from ts to te from data as text
  def copy(data, ts, te)
    data[ts...te].pack('c*').force_encoding('utf-8')
  end

  # Appends one or more characters to the literal buffer, to be emitted later
  # by a call to emit_literal.
  def append_literal(data, ts, te)
    (self.literal_run ||= []) << copy(data, ts, te)
  end

  # Emits the literal run collected by calls to the append_literal method.
  def emit_literal
    text = literal_run.join
    self.literal_run = nil
    emit(:literal, :literal, text)
  end

  def emit_options(text)
    token = nil

    # Ruby allows things like '(?-xxxx)' or '(?xx-xx--xx-:abc)'.
    text =~ /\(\?([mixdau]*)(-(?:[mix]*))*(:)?/
    positive, negative, group_local = $1,$2,$3

    if positive.include?('x')
      self.free_spacing = true
    end

    # If the x appears in both, treat it like ruby does, the second cancels
    # the first.
    if negative && negative.include?('x')
      self.free_spacing = false
    end

    if group_local
      spacing_stack << {:free_spacing => free_spacing, :depth => group_depth}
      token = :options
    else
      # switch for parent group level
      spacing_stack.last[:free_spacing] = free_spacing
      token = :options_switch
    end

    emit(:group, token, text)
  end

  def emit_meta_control_sequence(data, ts, te, token)
    if data.last < 0x00 || data.last > 0x7F
      raise ValidationError.for(:sequence, 'escape', token.to_s)
    end
    emit(:escape, token, copy(data, ts-1,te))
  end
end # module Regexp::Scanner
