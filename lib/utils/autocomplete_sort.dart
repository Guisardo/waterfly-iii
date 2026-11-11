// Canonical accent groups from Unicode 17.0.0 (NFD).
const Map<String, String> _accentGroups = <String, String>{
  '\u{41}':
      '\u{c0}\u{c1}\u{c2}\u{c3}\u{c4}\u{c5}\u{100}\u{102}\u{104}\u{1cd}\u{1de}\u{1e0}\u{1fa}\u{200}\u{202}\u{226}\u{1e00}\u{1ea0}\u{1ea2}\u{1ea4}\u{1ea6}\u{1ea8}\u{1eaa}\u{1eac}\u{1eae}\u{1eb0}\u{1eb2}\u{1eb4}\u{1eb6}\u{212b}',
  '\u{43}': '\u{c7}\u{106}\u{108}\u{10a}\u{10c}\u{1e08}',
  '\u{45}':
      '\u{c8}\u{c9}\u{ca}\u{cb}\u{112}\u{114}\u{116}\u{118}\u{11a}\u{204}\u{206}\u{228}\u{1e14}\u{1e16}\u{1e18}\u{1e1a}\u{1e1c}\u{1eb8}\u{1eba}\u{1ebc}\u{1ebe}\u{1ec0}\u{1ec2}\u{1ec4}\u{1ec6}',
  '\u{49}':
      '\u{cc}\u{cd}\u{ce}\u{cf}\u{128}\u{12a}\u{12c}\u{12e}\u{130}\u{1cf}\u{208}\u{20a}\u{1e2c}\u{1e2e}\u{1ec8}\u{1eca}',
  '\u{4e}':
      '\u{d1}\u{143}\u{145}\u{147}\u{1f8}\u{1e44}\u{1e46}\u{1e48}\u{1e4a}',
  '\u{4f}':
      '\u{d2}\u{d3}\u{d4}\u{d5}\u{d6}\u{14c}\u{14e}\u{150}\u{1a0}\u{1d1}\u{1ea}\u{1ec}\u{20c}\u{20e}\u{22a}\u{22c}\u{22e}\u{230}\u{1e4c}\u{1e4e}\u{1e50}\u{1e52}\u{1ecc}\u{1ece}\u{1ed0}\u{1ed2}\u{1ed4}\u{1ed6}\u{1ed8}\u{1eda}\u{1edc}\u{1ede}\u{1ee0}\u{1ee2}',
  '\u{55}':
      '\u{d9}\u{da}\u{db}\u{dc}\u{168}\u{16a}\u{16c}\u{16e}\u{170}\u{172}\u{1af}\u{1d3}\u{1d5}\u{1d7}\u{1d9}\u{1db}\u{214}\u{216}\u{1e72}\u{1e74}\u{1e76}\u{1e78}\u{1e7a}\u{1ee4}\u{1ee6}\u{1ee8}\u{1eea}\u{1eec}\u{1eee}\u{1ef0}',
  '\u{59}':
      '\u{dd}\u{176}\u{178}\u{232}\u{1e8e}\u{1ef2}\u{1ef4}\u{1ef6}\u{1ef8}',
  '\u{61}':
      '\u{e0}\u{e1}\u{e2}\u{e3}\u{e4}\u{e5}\u{101}\u{103}\u{105}\u{1ce}\u{1df}\u{1e1}\u{1fb}\u{201}\u{203}\u{227}\u{1e01}\u{1ea1}\u{1ea3}\u{1ea5}\u{1ea7}\u{1ea9}\u{1eab}\u{1ead}\u{1eaf}\u{1eb1}\u{1eb3}\u{1eb5}\u{1eb7}',
  '\u{63}': '\u{e7}\u{107}\u{109}\u{10b}\u{10d}\u{1e09}',
  '\u{65}':
      '\u{e8}\u{e9}\u{ea}\u{eb}\u{113}\u{115}\u{117}\u{119}\u{11b}\u{205}\u{207}\u{229}\u{1e15}\u{1e17}\u{1e19}\u{1e1b}\u{1e1d}\u{1eb9}\u{1ebb}\u{1ebd}\u{1ebf}\u{1ec1}\u{1ec3}\u{1ec5}\u{1ec7}',
  '\u{69}':
      '\u{ec}\u{ed}\u{ee}\u{ef}\u{129}\u{12b}\u{12d}\u{12f}\u{1d0}\u{209}\u{20b}\u{1e2d}\u{1e2f}\u{1ec9}\u{1ecb}',
  '\u{6e}':
      '\u{f1}\u{144}\u{146}\u{148}\u{1f9}\u{1e45}\u{1e47}\u{1e49}\u{1e4b}',
  '\u{6f}':
      '\u{f2}\u{f3}\u{f4}\u{f5}\u{f6}\u{14d}\u{14f}\u{151}\u{1a1}\u{1d2}\u{1eb}\u{1ed}\u{20d}\u{20f}\u{22b}\u{22d}\u{22f}\u{231}\u{1e4d}\u{1e4f}\u{1e51}\u{1e53}\u{1ecd}\u{1ecf}\u{1ed1}\u{1ed3}\u{1ed5}\u{1ed7}\u{1ed9}\u{1edb}\u{1edd}\u{1edf}\u{1ee1}\u{1ee3}',
  '\u{75}':
      '\u{f9}\u{fa}\u{fb}\u{fc}\u{169}\u{16b}\u{16d}\u{16f}\u{171}\u{173}\u{1b0}\u{1d4}\u{1d6}\u{1d8}\u{1da}\u{1dc}\u{215}\u{217}\u{1e73}\u{1e75}\u{1e77}\u{1e79}\u{1e7b}\u{1ee5}\u{1ee7}\u{1ee9}\u{1eeb}\u{1eed}\u{1eef}\u{1ef1}',
  '\u{79}':
      '\u{fd}\u{ff}\u{177}\u{233}\u{1e8f}\u{1e99}\u{1ef3}\u{1ef5}\u{1ef7}\u{1ef9}',
  '\u{44}': '\u{10e}\u{1e0a}\u{1e0c}\u{1e0e}\u{1e10}\u{1e12}',
  '\u{64}': '\u{10f}\u{1e0b}\u{1e0d}\u{1e0f}\u{1e11}\u{1e13}',
  '\u{47}': '\u{11c}\u{11e}\u{120}\u{122}\u{1e6}\u{1f4}\u{1e20}',
  '\u{67}': '\u{11d}\u{11f}\u{121}\u{123}\u{1e7}\u{1f5}\u{1e21}',
  '\u{48}': '\u{124}\u{21e}\u{1e22}\u{1e24}\u{1e26}\u{1e28}\u{1e2a}',
  '\u{68}': '\u{125}\u{21f}\u{1e23}\u{1e25}\u{1e27}\u{1e29}\u{1e2b}\u{1e96}',
  '\u{4a}': '\u{134}',
  '\u{6a}': '\u{135}\u{1f0}',
  '\u{4b}': '\u{136}\u{1e8}\u{1e30}\u{1e32}\u{1e34}',
  '\u{6b}': '\u{137}\u{1e9}\u{1e31}\u{1e33}\u{1e35}',
  '\u{4c}': '\u{139}\u{13b}\u{13d}\u{1e36}\u{1e38}\u{1e3a}\u{1e3c}',
  '\u{6c}': '\u{13a}\u{13c}\u{13e}\u{1e37}\u{1e39}\u{1e3b}\u{1e3d}',
  '\u{52}':
      '\u{154}\u{156}\u{158}\u{210}\u{212}\u{1e58}\u{1e5a}\u{1e5c}\u{1e5e}',
  '\u{72}':
      '\u{155}\u{157}\u{159}\u{211}\u{213}\u{1e59}\u{1e5b}\u{1e5d}\u{1e5f}',
  '\u{53}':
      '\u{15a}\u{15c}\u{15e}\u{160}\u{218}\u{1e60}\u{1e62}\u{1e64}\u{1e66}\u{1e68}',
  '\u{73}':
      '\u{15b}\u{15d}\u{15f}\u{161}\u{219}\u{1e61}\u{1e63}\u{1e65}\u{1e67}\u{1e69}',
  '\u{54}': '\u{162}\u{164}\u{21a}\u{1e6a}\u{1e6c}\u{1e6e}\u{1e70}',
  '\u{74}': '\u{163}\u{165}\u{21b}\u{1e6b}\u{1e6d}\u{1e6f}\u{1e71}\u{1e97}',
  '\u{57}': '\u{174}\u{1e80}\u{1e82}\u{1e84}\u{1e86}\u{1e88}',
  '\u{77}': '\u{175}\u{1e81}\u{1e83}\u{1e85}\u{1e87}\u{1e89}\u{1e98}',
  '\u{5a}': '\u{179}\u{17b}\u{17d}\u{1e90}\u{1e92}\u{1e94}',
  '\u{7a}': '\u{17a}\u{17c}\u{17e}\u{1e91}\u{1e93}\u{1e95}',
  '\u{c6}': '\u{1e2}\u{1fc}',
  '\u{e6}': '\u{1e3}\u{1fd}',
  '\u{1b7}': '\u{1ee}',
  '\u{292}': '\u{1ef}',
  '\u{d8}': '\u{1fe}',
  '\u{f8}': '\u{1ff}',
  '\u{391}':
      '\u{386}\u{1f08}\u{1f09}\u{1f0a}\u{1f0b}\u{1f0c}\u{1f0d}\u{1f0e}\u{1f0f}\u{1f88}\u{1f89}\u{1f8a}\u{1f8b}\u{1f8c}\u{1f8d}\u{1f8e}\u{1f8f}\u{1fb8}\u{1fb9}\u{1fba}\u{1fbb}\u{1fbc}',
  '\u{395}':
      '\u{388}\u{1f18}\u{1f19}\u{1f1a}\u{1f1b}\u{1f1c}\u{1f1d}\u{1fc8}\u{1fc9}',
  '\u{397}':
      '\u{389}\u{1f28}\u{1f29}\u{1f2a}\u{1f2b}\u{1f2c}\u{1f2d}\u{1f2e}\u{1f2f}\u{1f98}\u{1f99}\u{1f9a}\u{1f9b}\u{1f9c}\u{1f9d}\u{1f9e}\u{1f9f}\u{1fca}\u{1fcb}\u{1fcc}',
  '\u{399}':
      '\u{38a}\u{3aa}\u{1f38}\u{1f39}\u{1f3a}\u{1f3b}\u{1f3c}\u{1f3d}\u{1f3e}\u{1f3f}\u{1fd8}\u{1fd9}\u{1fda}\u{1fdb}',
  '\u{39f}':
      '\u{38c}\u{1f48}\u{1f49}\u{1f4a}\u{1f4b}\u{1f4c}\u{1f4d}\u{1ff8}\u{1ff9}',
  '\u{3a5}':
      '\u{38e}\u{3ab}\u{1f59}\u{1f5b}\u{1f5d}\u{1f5f}\u{1fe8}\u{1fe9}\u{1fea}\u{1feb}',
  '\u{3a9}':
      '\u{38f}\u{1f68}\u{1f69}\u{1f6a}\u{1f6b}\u{1f6c}\u{1f6d}\u{1f6e}\u{1f6f}\u{1fa8}\u{1fa9}\u{1faa}\u{1fab}\u{1fac}\u{1fad}\u{1fae}\u{1faf}\u{1ffa}\u{1ffb}\u{1ffc}',
  '\u{3b9}':
      '\u{390}\u{3af}\u{3ca}\u{1f30}\u{1f31}\u{1f32}\u{1f33}\u{1f34}\u{1f35}\u{1f36}\u{1f37}\u{1f76}\u{1f77}\u{1fd0}\u{1fd1}\u{1fd2}\u{1fd3}\u{1fd6}\u{1fd7}',
  '\u{3b1}':
      '\u{3ac}\u{1f00}\u{1f01}\u{1f02}\u{1f03}\u{1f04}\u{1f05}\u{1f06}\u{1f07}\u{1f70}\u{1f71}\u{1f80}\u{1f81}\u{1f82}\u{1f83}\u{1f84}\u{1f85}\u{1f86}\u{1f87}\u{1fb0}\u{1fb1}\u{1fb2}\u{1fb3}\u{1fb4}\u{1fb6}\u{1fb7}',
  '\u{3b5}':
      '\u{3ad}\u{1f10}\u{1f11}\u{1f12}\u{1f13}\u{1f14}\u{1f15}\u{1f72}\u{1f73}',
  '\u{3b7}':
      '\u{3ae}\u{1f20}\u{1f21}\u{1f22}\u{1f23}\u{1f24}\u{1f25}\u{1f26}\u{1f27}\u{1f74}\u{1f75}\u{1f90}\u{1f91}\u{1f92}\u{1f93}\u{1f94}\u{1f95}\u{1f96}\u{1f97}\u{1fc2}\u{1fc3}\u{1fc4}\u{1fc6}\u{1fc7}',
  '\u{3c5}':
      '\u{3b0}\u{3cb}\u{3cd}\u{1f50}\u{1f51}\u{1f52}\u{1f53}\u{1f54}\u{1f55}\u{1f56}\u{1f57}\u{1f7a}\u{1f7b}\u{1fe0}\u{1fe1}\u{1fe2}\u{1fe3}\u{1fe6}\u{1fe7}',
  '\u{3bf}':
      '\u{3cc}\u{1f40}\u{1f41}\u{1f42}\u{1f43}\u{1f44}\u{1f45}\u{1f78}\u{1f79}',
  '\u{3c9}':
      '\u{3ce}\u{1f60}\u{1f61}\u{1f62}\u{1f63}\u{1f64}\u{1f65}\u{1f66}\u{1f67}\u{1f7c}\u{1f7d}\u{1fa0}\u{1fa1}\u{1fa2}\u{1fa3}\u{1fa4}\u{1fa5}\u{1fa6}\u{1fa7}\u{1ff2}\u{1ff3}\u{1ff4}\u{1ff6}\u{1ff7}',
  '\u{3d2}': '\u{3d3}\u{3d4}',
  '\u{415}': '\u{400}\u{401}\u{4d6}',
  '\u{413}': '\u{403}',
  '\u{406}': '\u{407}',
  '\u{41a}': '\u{40c}',
  '\u{418}': '\u{40d}\u{419}\u{4e2}\u{4e4}',
  '\u{423}': '\u{40e}\u{4ee}\u{4f0}\u{4f2}',
  '\u{438}': '\u{439}\u{45d}\u{4e3}\u{4e5}',
  '\u{435}': '\u{450}\u{451}\u{4d7}',
  '\u{433}': '\u{453}',
  '\u{456}': '\u{457}',
  '\u{43a}': '\u{45c}',
  '\u{443}': '\u{45e}\u{4ef}\u{4f1}\u{4f3}',
  '\u{474}': '\u{476}',
  '\u{475}': '\u{477}',
  '\u{416}': '\u{4c1}\u{4dc}',
  '\u{436}': '\u{4c2}\u{4dd}',
  '\u{410}': '\u{4d0}\u{4d2}',
  '\u{430}': '\u{4d1}\u{4d3}',
  '\u{4d8}': '\u{4da}',
  '\u{4d9}': '\u{4db}',
  '\u{417}': '\u{4de}',
  '\u{437}': '\u{4df}',
  '\u{41e}': '\u{4e6}',
  '\u{43e}': '\u{4e7}',
  '\u{4e8}': '\u{4ea}',
  '\u{4e9}': '\u{4eb}',
  '\u{42d}': '\u{4ec}',
  '\u{44d}': '\u{4ed}',
  '\u{427}': '\u{4f4}',
  '\u{447}': '\u{4f5}',
  '\u{42b}': '\u{4f8}',
  '\u{44b}': '\u{4f9}',
  '\u{627}': '\u{622}\u{623}\u{625}',
  '\u{648}': '\u{624}',
  '\u{64a}': '\u{626}',
  '\u{6d5}': '\u{6c0}',
  '\u{6c1}': '\u{6c2}',
  '\u{6d2}': '\u{6d3}',
  '\u{928}': '\u{929}',
  '\u{930}': '\u{931}',
  '\u{933}': '\u{934}',
  '\u{915}': '\u{958}',
  '\u{916}': '\u{959}',
  '\u{917}': '\u{95a}',
  '\u{91c}': '\u{95b}',
  '\u{921}': '\u{95c}',
  '\u{922}': '\u{95d}',
  '\u{92b}': '\u{95e}',
  '\u{92f}': '\u{95f}',
  '\u{9a1}': '\u{9dc}',
  '\u{9a2}': '\u{9dd}',
  '\u{9af}': '\u{9df}',
  '\u{a32}': '\u{a33}',
  '\u{a38}': '\u{a36}',
  '\u{a16}': '\u{a59}',
  '\u{a17}': '\u{a5a}',
  '\u{a1c}': '\u{a5b}',
  '\u{a2b}': '\u{a5e}',
  '\u{b21}': '\u{b5c}',
  '\u{b22}': '\u{b5d}',
  '\u{42}': '\u{1e02}\u{1e04}\u{1e06}',
  '\u{62}': '\u{1e03}\u{1e05}\u{1e07}',
  '\u{46}': '\u{1e1e}',
  '\u{66}': '\u{1e1f}',
  '\u{4d}': '\u{1e3e}\u{1e40}\u{1e42}',
  '\u{6d}': '\u{1e3f}\u{1e41}\u{1e43}',
  '\u{50}': '\u{1e54}\u{1e56}',
  '\u{70}': '\u{1e55}\u{1e57}',
  '\u{56}': '\u{1e7c}\u{1e7e}',
  '\u{76}': '\u{1e7d}\u{1e7f}',
  '\u{58}': '\u{1e8a}\u{1e8c}',
  '\u{78}': '\u{1e8b}\u{1e8d}',
  '\u{17f}': '\u{1e9b}',
  '\u{3c1}': '\u{1fe4}\u{1fe5}',
  '\u{3a1}': '\u{1fec}',
  '\u{304b}': '\u{304c}',
  '\u{304d}': '\u{304e}',
  '\u{304f}': '\u{3050}',
  '\u{3051}': '\u{3052}',
  '\u{3053}': '\u{3054}',
  '\u{3055}': '\u{3056}',
  '\u{3057}': '\u{3058}',
  '\u{3059}': '\u{305a}',
  '\u{305b}': '\u{305c}',
  '\u{305d}': '\u{305e}',
  '\u{305f}': '\u{3060}',
  '\u{3061}': '\u{3062}',
  '\u{3064}': '\u{3065}',
  '\u{3066}': '\u{3067}',
  '\u{3068}': '\u{3069}',
  '\u{306f}': '\u{3070}\u{3071}',
  '\u{3072}': '\u{3073}\u{3074}',
  '\u{3075}': '\u{3076}\u{3077}',
  '\u{3078}': '\u{3079}\u{307a}',
  '\u{307b}': '\u{307c}\u{307d}',
  '\u{3046}': '\u{3094}',
  '\u{309d}': '\u{309e}',
  '\u{30ab}': '\u{30ac}',
  '\u{30ad}': '\u{30ae}',
  '\u{30af}': '\u{30b0}',
  '\u{30b1}': '\u{30b2}',
  '\u{30b3}': '\u{30b4}',
  '\u{30b5}': '\u{30b6}',
  '\u{30b7}': '\u{30b8}',
  '\u{30b9}': '\u{30ba}',
  '\u{30bb}': '\u{30bc}',
  '\u{30bd}': '\u{30be}',
  '\u{30bf}': '\u{30c0}',
  '\u{30c1}': '\u{30c2}',
  '\u{30c4}': '\u{30c5}',
  '\u{30c6}': '\u{30c7}',
  '\u{30c8}': '\u{30c9}',
  '\u{30cf}': '\u{30d0}\u{30d1}',
  '\u{30d2}': '\u{30d3}\u{30d4}',
  '\u{30d5}': '\u{30d6}\u{30d7}',
  '\u{30d8}': '\u{30d9}\u{30da}',
  '\u{30db}': '\u{30dc}\u{30dd}',
  '\u{30a6}': '\u{30f4}',
  '\u{30ef}': '\u{30f7}',
  '\u{30f0}': '\u{30f8}',
  '\u{30f1}': '\u{30f9}',
  '\u{30f2}': '\u{30fa}',
  '\u{30fd}': '\u{30fe}',
  '\u{5d9}': '\u{fb1d}\u{fb39}',
  '\u{5f2}': '\u{fb1f}',
  '\u{5e9}': '\u{fb2a}\u{fb2b}\u{fb2c}\u{fb2d}\u{fb49}',
  '\u{5d0}': '\u{fb2e}\u{fb2f}\u{fb30}',
  '\u{5d1}': '\u{fb31}\u{fb4c}',
  '\u{5d2}': '\u{fb32}',
  '\u{5d3}': '\u{fb33}',
  '\u{5d4}': '\u{fb34}',
  '\u{5d5}': '\u{fb35}\u{fb4b}',
  '\u{5d6}': '\u{fb36}',
  '\u{5d8}': '\u{fb38}',
  '\u{5da}': '\u{fb3a}',
  '\u{5db}': '\u{fb3b}\u{fb4d}',
  '\u{5dc}': '\u{fb3c}',
  '\u{5de}': '\u{fb3e}',
  '\u{5e0}': '\u{fb40}',
  '\u{5e1}': '\u{fb41}',
  '\u{5e3}': '\u{fb43}',
  '\u{5e4}': '\u{fb44}\u{fb4e}',
  '\u{5e6}': '\u{fb46}',
  '\u{5e7}': '\u{fb47}',
  '\u{5e8}': '\u{fb48}',
  '\u{5ea}': '\u{fb4a}',
  '\u{105d2}': '\u{105c9}',
  '\u{105da}': '\u{105e4}',
  '\u{11099}': '\u{1109a}',
  '\u{1109b}': '\u{1109c}',
  '\u{110a5}': '\u{110ab}',
};
final Map<int, String> _accentBases = <int, String>{
  for (final MapEntry<String, String> group in _accentGroups.entries)
    for (final int rune in group.value.runes) rune: group.key,
};
final RegExp _combiningAccents = RegExp(
  r'[\u{300}-\u{34e}\u{350}-\u{36f}\u{483}-\u{487}\u{591}-\u{5bd}\u{5bf}-\u{5bf}\u{5c1}-\u{5c2}\u{5c4}-\u{5c5}\u{5c7}-\u{5c7}\u{610}-\u{61a}\u{64b}-\u{65f}\u{670}-\u{670}\u{6d6}-\u{6dc}\u{6df}-\u{6e4}\u{6e7}-\u{6e8}\u{6ea}-\u{6ed}\u{711}-\u{711}\u{730}-\u{74a}\u{7eb}-\u{7f3}\u{7fd}-\u{7fd}\u{816}-\u{819}\u{81b}-\u{823}\u{825}-\u{827}\u{829}-\u{82d}\u{859}-\u{85b}\u{897}-\u{89f}\u{8ca}-\u{8e1}\u{8e3}-\u{8ff}\u{93c}-\u{93c}\u{94d}-\u{94d}\u{951}-\u{954}\u{9bc}-\u{9bc}\u{9cd}-\u{9cd}\u{9fe}-\u{9fe}\u{a3c}-\u{a3c}\u{a4d}-\u{a4d}\u{abc}-\u{abc}\u{acd}-\u{acd}\u{b3c}-\u{b3c}\u{b4d}-\u{b4d}\u{bcd}-\u{bcd}\u{c3c}-\u{c3c}\u{c4d}-\u{c4d}\u{c55}-\u{c56}\u{cbc}-\u{cbc}\u{ccd}-\u{ccd}\u{d3b}-\u{d3c}\u{d4d}-\u{d4d}\u{dca}-\u{dca}\u{e38}-\u{e3a}\u{e48}-\u{e4b}\u{eb8}-\u{eba}\u{ec8}-\u{ecb}\u{f18}-\u{f19}\u{f35}-\u{f35}\u{f37}-\u{f37}\u{f39}-\u{f39}\u{f71}-\u{f72}\u{f74}-\u{f74}\u{f7a}-\u{f7d}\u{f80}-\u{f80}\u{f82}-\u{f84}\u{f86}-\u{f87}\u{fc6}-\u{fc6}\u{1037}-\u{1037}\u{1039}-\u{103a}\u{108d}-\u{108d}\u{135d}-\u{135f}\u{1714}-\u{1715}\u{1734}-\u{1734}\u{17d2}-\u{17d2}\u{17dd}-\u{17dd}\u{18a9}-\u{18a9}\u{1939}-\u{193b}\u{1a17}-\u{1a18}\u{1a60}-\u{1a60}\u{1a75}-\u{1a7c}\u{1a7f}-\u{1a7f}\u{1ab0}-\u{1abd}\u{1abf}-\u{1add}\u{1ae0}-\u{1aeb}\u{1b34}-\u{1b34}\u{1b44}-\u{1b44}\u{1b6b}-\u{1b73}\u{1baa}-\u{1bab}\u{1be6}-\u{1be6}\u{1bf2}-\u{1bf3}\u{1c37}-\u{1c37}\u{1cd0}-\u{1cd2}\u{1cd4}-\u{1ce0}\u{1ce2}-\u{1ce8}\u{1ced}-\u{1ced}\u{1cf4}-\u{1cf4}\u{1cf8}-\u{1cf9}\u{1dc0}-\u{1dff}\u{20d0}-\u{20dc}\u{20e1}-\u{20e1}\u{20e5}-\u{20f0}\u{2cef}-\u{2cf1}\u{2d7f}-\u{2d7f}\u{2de0}-\u{2dff}\u{302a}-\u{302f}\u{3099}-\u{309a}\u{a66f}-\u{a66f}\u{a674}-\u{a67d}\u{a69e}-\u{a69f}\u{a6f0}-\u{a6f1}\u{a806}-\u{a806}\u{a82c}-\u{a82c}\u{a8c4}-\u{a8c4}\u{a8e0}-\u{a8f1}\u{a92b}-\u{a92d}\u{a953}-\u{a953}\u{a9b3}-\u{a9b3}\u{a9c0}-\u{a9c0}\u{aab0}-\u{aab0}\u{aab2}-\u{aab4}\u{aab7}-\u{aab8}\u{aabe}-\u{aabf}\u{aac1}-\u{aac1}\u{aaf6}-\u{aaf6}\u{abed}-\u{abed}\u{fb1e}-\u{fb1e}\u{fe20}-\u{fe2f}\u{101fd}-\u{101fd}\u{102e0}-\u{102e0}\u{10376}-\u{1037a}\u{10a0d}-\u{10a0d}\u{10a0f}-\u{10a0f}\u{10a38}-\u{10a3a}\u{10a3f}-\u{10a3f}\u{10ae5}-\u{10ae6}\u{10d24}-\u{10d27}\u{10d69}-\u{10d6d}\u{10eab}-\u{10eac}\u{10efa}-\u{10efb}\u{10efd}-\u{10eff}\u{10f46}-\u{10f50}\u{10f82}-\u{10f85}\u{11046}-\u{11046}\u{11070}-\u{11070}\u{1107f}-\u{1107f}\u{110b9}-\u{110ba}\u{11100}-\u{11102}\u{11133}-\u{11134}\u{11173}-\u{11173}\u{111c0}-\u{111c0}\u{111ca}-\u{111ca}\u{11235}-\u{11236}\u{112e9}-\u{112ea}\u{1133b}-\u{1133c}\u{1134d}-\u{1134d}\u{11366}-\u{1136c}\u{11370}-\u{11374}\u{113ce}-\u{113d0}\u{11442}-\u{11442}\u{11446}-\u{11446}\u{1145e}-\u{1145e}\u{114c2}-\u{114c3}\u{115bf}-\u{115c0}\u{1163f}-\u{1163f}\u{116b6}-\u{116b7}\u{1172b}-\u{1172b}\u{11839}-\u{1183a}\u{1193d}-\u{1193e}\u{11943}-\u{11943}\u{119e0}-\u{119e0}\u{11a34}-\u{11a34}\u{11a47}-\u{11a47}\u{11a99}-\u{11a99}\u{11c3f}-\u{11c3f}\u{11d42}-\u{11d42}\u{11d44}-\u{11d45}\u{11d97}-\u{11d97}\u{11f41}-\u{11f42}\u{1612f}-\u{1612f}\u{16af0}-\u{16af4}\u{16b30}-\u{16b36}\u{16ff0}-\u{16ff1}\u{1bc9e}-\u{1bc9e}\u{1d165}-\u{1d169}\u{1d16d}-\u{1d172}\u{1d17b}-\u{1d182}\u{1d185}-\u{1d18b}\u{1d1aa}-\u{1d1ad}\u{1d242}-\u{1d244}\u{1e000}-\u{1e006}\u{1e008}-\u{1e018}\u{1e01b}-\u{1e021}\u{1e023}-\u{1e024}\u{1e026}-\u{1e02a}\u{1e08f}-\u{1e08f}\u{1e130}-\u{1e136}\u{1e2ae}-\u{1e2ae}\u{1e2ec}-\u{1e2ef}\u{1e4ec}-\u{1e4ef}\u{1e5ee}-\u{1e5ef}\u{1e6e3}-\u{1e6e3}\u{1e6e6}-\u{1e6e6}\u{1e6ee}-\u{1e6ef}\u{1e6f5}-\u{1e6f5}\u{1e8d0}-\u{1e8d6}\u{1e944}-\u{1e94a}]',
  unicode: true,
);

/// Comparison key only; original labels and stored values stay unchanged.
String autocompleteSortKey(String value) => value.runes
    .map((int rune) => _accentBases[rune] ?? String.fromCharCode(rune))
    .join()
    .replaceAll(_combiningAccents, '')
    .toLowerCase();

int compareAutocompleteLabels(String a, String b) =>
    autocompleteSortKey(a).compareTo(autocompleteSortKey(b));

/// Stable ties preserve source order, duplicates and object identity.
List<T> sortedAutocompleteOptions<T>(
  Iterable<T> options,
  String Function(T) label,
) {
  final List<({T value, String key, int index})> indexed = options.indexed
      .map(
        ((int, T) entry) => (
          value: entry.$2,
          key: autocompleteSortKey(label(entry.$2)),
          index: entry.$1,
        ),
      )
      .toList();
  indexed.sort((
    ({T value, String key, int index}) a,
    ({T value, String key, int index}) b,
  ) {
    final int comparison = a.key.compareTo(b.key);
    return comparison != 0 ? comparison : a.index.compareTo(b.index);
  });
  return indexed
      .map((({T value, String key, int index}) entry) => entry.value)
      .toList();
}
