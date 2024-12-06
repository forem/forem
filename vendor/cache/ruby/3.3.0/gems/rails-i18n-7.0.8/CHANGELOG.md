## unreleased


## 7.0.8 (2022-08-15)

- Update following locales:
  - Bengali (bn): Add missing keys (`almost_x_years`) #1094
  - English (en-US): Normalize and add missing keys (`in` and `round_mode`) #1095
  - Korean (ko): Add missing keys (`in` and `round_mode`) #1097
  - Norwegian (nb): Fix extra `%{count}` interpolation in `has_one` key #1082
  - Portuguese (pt pt-BR): Add missing keys (`round_mode) #1100
  - Spanish (es-419 es-AR es-CL es-CO es-CR es-EC es-MX es-NI es-PA es-PE es-US es-VE): Fix typo in word _carácter_ #1090
  - Spanish (es-419 es-AR es-CL es-CO es-CR es-EC es-ES es-MX es-NI es-PA es-PE es-US es-VE): Normalize and add missing keys (`in`) #1089
  - Ukranian: Use hryvnia symbol as a currency unit #1093

## 7.0.7 (2022-05-12)

- Non-numerics counts are considered as `other` in all pluralizations #1067
- Update following locales:
  - Afrikaan (af): ZAR currency format #1066
  - English (en-ZA): ZAR currency format #1066
  - German (de, de-DE, de-AT, de-CH): Use abbreviated months in the short time format #1062
  - Japanese (ja): Add `in` and `round_mode` keys #1059
  - Korean (ko): Fix typo in `equal_to` keys #1061
  - Portuguese (pt, pt-BR): add translation for `errors.messages.in` #1071
  - Scottish Gaelic (gd): Add locale
  - Russian (ru): fix some errors in 'datetime' section, add `errors.messages.in` and `number.format.round_mode` keys #1077
  - Spanish (es): add translation for `errors.messages.in` #1071
  - French (fr, fr-CA, fr-CH, fr-FR): fix typo on 'almost_x_years: one' #1074
  - Indonesian (id): Remove duplicate spaces in `id.datetime.distance_in_words.less_than_x_minutes.other` #1079
  - Romanian (ro): Correction of Saturday in Romanian #1078
  - Croatian (hr): use lowercase for month and weekday names #1081
- Add ordinalization for German (de, de-AT, de-CH, de-DE)
- Remove keys that are present twice from Latvian (lv), Albanian (sq) #1080

## 7.0.6 (2022-11-08)

- Add option to choose which modules (locales, pluralization, transliteration,
  ordinals) are enabled #1019
- Add following locales:
  - Dzongkha (dz) #1052
  - Sardinian (sc) #1030
  - Swedish (sv-FI): Finland’s native Swedish-speakers #1055
- Update following locales:
  - Bengali (bn): Fix date and spelling issues #1031
  - Chinese (zh-HK, zh-TW, zh-YUE, zh-CN):
    - Simplify pluralization #1032 #1033 #1036
    - Standardize punctuation #997
  - English (en, en-CY, en-IE, en-TT, en-US, en-ZA):
    - Add pluralization #1021
    - Add `in` and `round_mode` keys #1042
  - French (fr, fr-CA, fr-CH, fr-CA):
    - Change an abreviation for March month in abbr_month_names #1002
    - Add `in` and `round_mode` keys #1046
  - Galician (gl): Add missing accent on `incluído` #961
  - German (de-AT, de-CH, de-DE, de):
    - Add transliteration rule for `ẞ` #1025
    - Add `eb` and `pb` storage units #1043
    - Add `round_mode` key #1044
  - Greek (el-CY): Add pluralization #1022
  - Japanese (ja): Simplify pluralization #1038
  - Korean (ko):
    - Language improvements #989
    - Simplify pluralization #1037
  - Latvian (lv): Add multiple missing translations #966
  - Spanish (es, es-419, es-AR, es-CL, es-CO, es-CR, es-ES, es-MX, es-NI, es-PA,
    es-PE, es-US, es-VE): Add `round_mode` key #1045
  - Swedish (sv-SE): Adjust precision and add some missing keys #1047
  - Vietnamese (vi):
    - Update translation for taken #1009
    - Simplify pluralization #1035
- Removed pluralizations rules that do not have locale files: ak, am, bh, bm,
  bo, br, by, cy, dz, ff, ga, gd, guw, gv, ig, ii, iu, jv, kab, kde, kea, ksh,
  kw, lag, ln, mo, mt, my, naq, nso, root, sah, se, ses, sg, sh, shi, sma, smi,
  smj, smn, sms, ti, to, tzm, wa, yo, zh #1017
- Change instances of the `one` pluralization key to use `%{count}` interpolation #993

## 7.0.5 (2022-07-03)

- No changes.

## 7.0.4 (2022-07-03)

- Add following locales:
  - Western Frisian (fy) #985
  - Kazakh (kk) #945
- Update following locales:
  - Slovak (sk): Fixed missing message #994
  - French (fr): Revert remainder of NBSP characters #996
  - French (fr): Use no-padded date format #991
  - Arabic (ar): fix errors.messages.greater_than typo #998
  - South slavic pluralizers #987
- Update update.rb to fetch active_model locale #1000
- Remove eager loading of translations during boot phase (this is now done by Rails). #983

## 7.0.3 (2022-03-01)

- Revert long date formats on default "en" locale #980

## 7.0.2 (2022-02-12)

- Fix long date format for many locales #939 #943
- Update following locales:
  - Chinese (zh-TW) #941
  - Croatian (hr) #940
  - Danish (da) #802 #946 #947 #948
  - Finnish (fi) #949
  - French (fr) #968
  - Galician (gl) #961
  - Papiamento (pap-AW, pap-CW) #974 #975
  - Serbian (sr) #972
  - Spanish (es, es-CL, es-ES) #936
  - Swedish (sv) #935
  - Tamil (ta) #953
- Fix require statement in `rails/pluralization/tr` #964
- Add rails/ordinals to s.files in Gemspec #969
- Update i18n-tasks to be ActiveSupport 7+ ready #970

## 7.0.1 (2021-12-24)

- Fix ordinals loading.

## 7.0.0 (2021-12-23)

- Support Rails 7
- Drop support for Ruby 1.8
- Eager load translations during boot phase if possible.
- Translate ordinals (fr, fr-FR, fr-CA, fr-BE)
- Update following locales:
  - Albanian (sq)
  - Catalan (ca)
  - Chinese (zh-CN, zh-TW)
  - Croatian (hr)
  - Danish (da)
  - Finnish (fi)
  - French (fr, fr-FR, fr-CA, fr-BE)
  - Georgian (ka)
  - German (de)
  - Greek (el, el-CY)
  - Italian (it, it-CH)
  - Latvian (lv)
  - Lithuanian (lt)
  - Norwegian (nb)
  - Polish (pl)
  - Portuguese (pt-BR)
  - Romanian (ro)
  - Serbian (sr)
  - Spanish (es-CO, es-AR)
  - Swedish (sv)
  - Turkish (tr)
  - Ukrainian (uk)
  - Vietnamese (vi)
- Add following locales:
  - English Trinidad & Tobago (en-TT)
  - Papiamento (pap-AW, pap-CW)
  - Sesotho (st)

## 6.0.0 (2019-08-17)

- Update rails-i18n.gemspec to use Railties 6.0.0
- Add Malagasy (mg) locale
- Update following locales:
  - Afrikaans (af)
  - Arabic (ar)
  - Azerbaijani (az)
  - Belarusian (be)
  - Bulgarian (bg)
  - Bengali (bn)
  - Bosnian (bs)
  - Catalan (ca)
  - Czech (cs)
  - Welsh (cy)
  - Danish (da)
  - German (de-AT, de-CH, de-DE, de)
  - Greek (el-CY, el)
  - English (en-AU, en-CA, en-CY, en-GB, en-IE, en-IN, en-NZ, en-US, en-Za, en)
  - Esperanto (eo)
  - Spanish (es-419, es-AR, es-CL, es-CO, es-CR, es-EC, es-ES, es-MX, es-NI, es-PA, es-PE, es-US, es-VE, es)
  - Estonian (et)
  - Basque (eu)
  - Farsi/Persian (fa)
  - Finnish (fi)
  - French (fr-CA, fr-CH, fr-FR, fr)
  - Galician (gl)
  - Hebrew (he)
  - Hindi (hi-IN, hi)
  - Croatian (hr)
  - Hungarian (hu)
  - Indonesian (id)
  - Icelandic (is)
  - Italian (it, it-CH)
  - Japanese (ja)
  - Georgian (ka)
  - Khmer (km)
  - Kannada (kn)
  - Korean (ko)
  - Luxembourgish (lb)
  - Lao (lo)
  - Lithuanian (lt)
  - Latvian (lv)
  - Malagasy (mg)
  - Macedonian (mk)
  - Malayalam (ml)
  - Mongolian (mn)
  - Marathi (mr-IN)
  - Malay (ms)
  - Norwegian Bokmål (nb)
  - Nepali (ne)
  - Dutch (nl)
  - Norwegian (nn)
  - Occitan (oc)
  - Oriya/Odiya (or)
  - Panjabi (pa)
  - Polish (pl)
  - Portuguese (pt-BR, pt)
  - Raeto-Romance (rm)
  - Romanian (ro)
  - Russian (ru)
  - Slovak (sk)
  - Slovenian (sl)
  - Albanian (sq)
  - Cyrillic Serbian (sr)
  - Swedish (sv-SE, sv)
  - Swahili (sw)
  - Tamil (ta)
  - Telugu (te)
  - Thai (th)
  - Tagalog (tl)
  - Turkish (tr)
  - Tatar (tt)
  - Uyghur (ug)
  - Ukrainian (uk)
  - Urdu (ur)
  - Uzbek (uz)
  - Vietnamese (vi)
  - Wolof (wo)
  - Chinese (zh-CN, zh-HK, zh-TW, zh-YUE)

## 6.0.0.beta1 (2019-01-28)

- Update rails-i18n.gemspec to use Railties 6.0.0.beta1
- Update Gemfile
- Update .travis.yml

## 5.1.3 (2019-01-28)

- Update following locales:
  - Spanish (es-*)
  - English (en-*)
  - Hungarian (hu)
  - Hebrew (he)
  - Cyrillic Serbian (sr)
  - Farsi/Persian (fa)

## 5.1.2 (2018-10-29)
- Add Telugu (te) locale
- Update following locales:
  - Azerbaijani (az)
  - Belarusian (be)
  - Czech (cs)
  - Danish (da)
  - English (en)
  - Spanish (es)
  - French (fr-*)
  - Japanese (ja)
  - Georgian (ka)
  - Korean (ko)
  - Lao (lo)
  - Occitan (oc)
  - Polish (pl)
  - Portuguese (pt-*)
  - Russian (ru)
  - Slovak (sk)
  - Ukrainian (uk)
  - Vietnamese (vi)
  - Chinese (zh-CN)
- Remove :fil inflector (#771)

## 5.1.1 (2018-02-26)
- Fix #767 (New Chinese pluralization rules break stuff)

## 5.1.0 (2018-02-14)
- Add following locales:
  - Spanish (Nicaragua) (es-NI)
  - Occitan (oc)
- Update following locales:
  - Azerbaijani (az)
  - Danish (da)
  - German (de)
  - Chinese (zh-*)
  - Vietnamese (vi)
  - Turkish (tr)
  - Portuguese (pt)
  - Finnish (fi)
  - Arabic (ar)
  - Czech (cs)
- Remove spec/integration directory and spork gem
- Bump gem dependencies to include i18n 1.0

## 5.0.4 (2017-05-06)
- Add following locales:
  - Cypriot Greek (el-CY)
  - Cypriot English (en-CY)
- Update following locales:
  - Swedish (sv, sv-SE)
  - Ukrainian (uk)
  - French (fr, fr-FR)
  - Japanese (ja)
  - Uzbek (uz)
  - Chinese (zh-CN, zh-HK, zh-TW, zh-YUE)
  - Spanish (es)

## 5.0.3 (2017-02-10)
- Update following locales:
  - Portuguese (pt, pt-BR)
  - Spanish locales (ES-\*)
  - Japanese (ja)
  - Georgian (ka)
  - Korean (ko)
  - Swedish (sv, sv-SE)
  - Ukrainian (uk)

## 5.0.2 (2016-12-29)
- Add following locales:
  - Georgian (ka)
- Update following locales:
  - Finnish (fi)
  - Azeri (az)
  - Bulgarian (bg)
  - Russian (ru)
  - Swedish (sv, sv-SE)
  - Spanish (es)
  - Danish (da)
  - Portuguese (pt-BR)
  - Basque (eu)
  - Nepali (ne)
  - Farsi/Persian (fa)
- Fix precision for human format on eo, es-PE, fr-CA, fr-CH, fr-FR, fr, pt-BR and tr

## 5.0.1 (2016-09-22)
- Update following locales:
  - Afrikaans (af)
  - Bosnian (bs)
  - Catalan (ca)
  - English (en-AU, en-CA, en-GB, en-IE, en-NZ, en-US, en-ZA, en)
  - Estonian (et)
  - French (fr-CA, fr-CH, fr-FR, fr)
  - Norwegian Bokmål (nb)
  - Russion (ru)
  - Wolof (wo)
  - Traditional Chinese (zh-TW)

## 5.0.0 (2016-07-05)
- Change the structure of translation files for Rails 5
- Update Spanish locales (ES-\*)
- Update Brazilian Portuguese (pt-BR)
- Update Dutch (nl)
- Update Arabic (ar)
- Add German (de-DE)
- Add French (fr-FR)
- Add Malayalam (ml)
- Update Chinese (zh-CN, zh-HK, zh-TW, zh-YUE)
- Update Khmer (km)
- Update German (de-AT, de-CH, de-DE, de)
- Update French (fr)
- Update Norwegian bokmål (nb)
- Update Norwegian (nn)
- Add Albanian (sq)
- Update Turkish (tr)
- Update Italian (it)
- Update Ukrainian (uk)
- Update Danish (da)
- Update Spanish, Panama (es-PA)
- Update Czech (cs)
- Update Portuguese (pt)
- Update Hebrew (he)

## 4.0.9 (2016-07-05)
- Update Bosnian (bs)
- Update Arabic (ar)
- Update Panjabi (pa)
- Update German (de)
- Update Spanish (es)
- Update Chinese (zh-CN, zh-TW)
- Add Albanian (sq)

## 4.0.8 (2015-12-24)
- Add Panjabi (pa)
- Update Russian (ru)

## 4.0.7 (2015-11-20)
- Update Khmer (km)
- Update Greek (el)
- Update German (de)

## 4.0.6 (2015-10-23)
- Depend on i18n (~> 0.7)
- Update Indonesian (id)
- Update German (de)
- Update Spanish (es)
- Update Russian (ru) - Revert "bringing the month names to uppercase"
- Update Turkish (tr) - Use turkish lira symbol instead of TL
- Update Dutch (nl)

## 4.0.5 (2015-09-06)
- Update Portuguese (pt)
- Update Korean (ko)
- Update Dutch (nl)
- Update German (de, de-AT, de-CH)
- Update Spanish (es, es-AR, es-CL, es-CO, es-CR, es-PE, es-US, es-VE)
- Update French (fr-CA, fr-CH, fr)
- Add Luxembourgish (lb)
- Add Marathi (mr-IN)
- Update Swedish (sv)
- Update Arabic (ar)
- Update Finnish (fi)
- Add Uyghur (ug)
- Update Japanese (ja)
- Update Russian (ru)
- Add Greek transliteration rules (el)
- Update Hebrew (he)
- Update Italian (it)
- Update Greek (el)

## 4.0.4 (2015-02-27)
 - Complete Brazilian Portuguese translation (pt-BR)
 - Fix east slavic pluralization and transliteration rules
 - Update Polish (pl)
 - Change confirmation error message for es-* locales
 - Update Swedish (sv)
 - Update French (fr)
 - Update Dutch (nl)
 - Update Swiss German (de-CH)
 - Update German (de, de-AT)
 - Update Turkish (tr)
 - Update Lithuanian (lt)
 - Update Urdu (ur)
 - Update Chinese (zh-CN, zh-HK, zh-TW, zh-YUE)
 - Update Khmer (km)
 - Update Italian (it)
 - Add Belarusian (be)
 - Add Tatar (tt)
 - Update Croatian (hr)

## 4.0.3 (2014-09-04)
 - Remove activemodel and activerecord namespaces
 - Update Hebrew translation (he)
 - Add Tamil (ta)
 - Update Ukrainian (uk)
 - Update Italian (it)
 - Update Dutch (nl)
 - Add es-US locale
 - Update Korean (ko)
 - Update Norwegian bokmål (nb)
 - Update Norwegian (nn)
 - Update Czech (cs)
 - Update Indonesian (id)
 - Update Chinese Simplified (zh-CN)
 - Complete Russian (ru)
 - Update Arabic (ar)
 - Update Turkish (tr)
 - Update Vietnamese (vi)
 - Update French (fr, fr-CA, fr-CH)
 - Update Croatian (hr)
 - Update Icelandic (is)
 - Update English (en, en-AU, en-CA, en-GB, en-IE, en-IN, en-NZ)
 - Update Wolof (wo)
 - Update Spanish/Mexico (es-MX)
 - Update German (de)
 - Update Latvian (lv)
 - Update Khmer (km)
 - Update Polish (po)

## 4.0.2 (2014-03-23)
 - Complete French translation (fr)
 - Make East Slavic pluralization faster
 - Update Upper Sorbian translation (dsb)
 - Add new locale Spanish for Ecuador (es-EC)
 - Update German translation for Switzerland (de-CH)
 - Update Hebrew translation (he)
 - Change currency for Latvian (lv)
 - Use two letter week day abbreviations for Dutch (nl)
 - Update Arabic translation (ar)
 - Update Hungarian translation (hu)
 - Change currency for Ireland (en-IE)
 - Update Ukrainian translation (uk)
 - Add Papiamento/Curaçao translation (pap-CW)
 - Add Cantonese translation (zh-YUE)
 - Update Portugese translation for Brazil (pt-BR)
 - Update Tagalog translation (tl)
 - Update English translation for India (en-IN)
 - Update Lithuanian translation (lt)
 - Update date formats for Finnish (fi)

## 4.0.1 (2013-12-19)
 - Fix typos, formats and delimiters for Swiss-German (iso-639-2/gsw-CH)
 - Add missing keys to Dutch (nl)
 - Fix translations for Lithuanian (lt)
 - Add Spanish/Panama (es-PA)
 - Add Urdu (ur)
 - Remove whitespace between attribute and message in Chinese (zh-CN)
 - Support Rails 4.1.0.beta1

## 4.0.0 (2013-10-05)
 - Fix values of 'restrict_dependent_destroy' key for many languages
 - Fix currency separator and delimiters for es-AR, fi, ro and sv
 - Fix 'errors.messages.too_(long|short)' for German (de)
 - Add transliteration rules for German (de)
 - Add missing keys to Chinese/Hong Kong (zh-HK)
 - Add English/Ireland (en-IE)
 - Add missing keys to Icelandic (is)
 - Add missing keys to Danish (da)
 - Fix a grammar error for Bulgarian (bg)
 - Order keys of French (fr) locale alphabetically
 - Singularize Millionen, Billionen for German/Switzerland (de-CH)
 - Fix date format for Italian (it)
 - Add transliteration rules for French (fr)
 - Add Spanish/Costa Rica (es-CR)
 - Remove trailing spaces for many languages
 - Fix abbr_month_names and month_names for Catalan (ca)
 - Reintroduce English/US (en-US)
 - Add transliteration rules for Romanian (ro)
 - Fix abbr_day_names and abbr_month_names for French (fr)
 - Fix 'storage_units.units.byte' key for Chinese/Taiwan (zh-TW)
 - Use 12-hour clock for :en-US and :en-CA
 - Fix 'date.formats.default' key in en-US locale
 - Fix some translations for Chinese/Hong Kong (zh-HK)
 - Fix translations for less_than_x_{minutes,seconds} for Japanese (ja)
 - Fix 'errors.messages.confirmation' key for Russian (ru)
 - Fix 'datetime.distance_in_words' keys for Hungarian (hu)
 - Fix the currency unit for Polish (pl)
 - Fix the currency unit for French/Switzerland (fr-CH)

## 0.7.4 (2013-07-04)
 - Add Oriya/Odiya language (or)
 - Revert several translations for Spanish/Colombia (es-CO)
 - Add Swiss-German (iso-639-2/gsw-CH)
 - Add Chinese/Hong Kong (zh-HK)
 - Fix some translations for Mongolian (mn)
 - Fix some translations for Hebrew (he)
 - Fix date and time formats for English/Austraria (en-AU)
 - Add English/New Zealand (en-NZ)
 - Fix some translations for Finnish (fi)
 - Fix the case in x_seconds for Russian (ru)
 - Add :many pluralization value for Polish (pl)
 - Change the value of strip_insignificant_zeros to false for Norwegian (nb)

## 0.7.3 (2013-03-19)
 - Fix number delimiter and separator for Italian (it)
 - Fix currency delimiter and separator for Romanian (ro)
 - Fix time formats for Portuguese/Brazil (pt-BR)
 - Fix several translations for Estonian (et)
 - Fix several translations for Spanish/Colombia (es-CO)
 - Fix the translation of half_a_minute for Tagalog (tl)
 - Fix separators for Russian (ru)
 - Add Afrikaans locale (af)
 - Fix some spelling mistakes for Catalan (ca)
 - Use secure Rubygems URL
 - Change capitalization rules for Italian (it)
 - Fix abbreviations, currency format, etc. for Greek (el)
 - Fix the translation of submit for Portuguese (pt)

## 0.7.2 (2012-12-28)
 - Remove spurious `mis` from Welsh month names
 - Add OneOther default pluralization rule and create corresponding locale pluralization files
 - Add pluralization files for locales with region
 - Update Persian (fa) translation

## 0.7.1 (2012-11-24)
 - Update Peruvian Spanish (es-PE) translation
 - Fix pluralization rules for OneTwoOther
 - Fix pluralization rules for Hungarian (hu)
 - Update Japanese (ja) translation
 - Fix and complete translations of Macedonian (mk), Cyrillic Serbian (sr) and Serbo-Croatian (scr)

## 0.7.0 (2012-10-23)
 - Remove Swiss German (gsw-CH) as a duplicate of de-CH
 - Remove en-US
 - Remove region code from bn-IN, gl-ES, pt-PT and sv-SE
 - Move iso-639-2 locales into their own directory
 - Add pluralization rule for Upper Sorbian
 - Fix grammar mistakes on Bulgarian (bg) translation
 - Add Latin American Spanish (es-419) translation

## 0.6.6 (2012-09-07)
 - added Uzbek (uz) translation
 - added Swiss Italian (it-CH) translation
 - fixed Swiss German (de-CH) translation
 - added Polish (pl) transliteration
 - fixed Greek (el) translation
 - added Nepali (ne) translation
 - fixed Argentina Spanish (es-AR) translation

## 0.6.5 (2012-07-02)
 - fixed Icelandic translation
 - fixed Portuguese translation
 - completed Vietnamese translation and transliteration
 - added Canadian English
 - fixed Tagalog delimiter and separator
 - fixed Bosinian translation
 - fixed French translation
 - added Engish (en) translation
 - added Spanish (Venizuela) translation
 - complted Turkish translation

## 0.6.4 (2012-05-17)
- fixed Croatian translation and pluralization
- added Wolof translation
- fixed Hebrew pluralization
- added Tagalog translation
- fixed Bosinan pluralization
- fixed Lativian pluralization

## 0.6.3 (2012-04-15)

- fixed English (India) translations
- fixed Hebrew pluralization

## 0.6.2 (2012-03-28)

- added a patch for Ruby 1.8.7 support

## 0.6.1 (2012-03-25)

- uses I18n.available_locales to load selected locales
- added transliteration rule for Ukrainian
- completed translations for Mongolian (mn)

## 0.5.2 (2012-03-17)

- fixed Polish pluralization
- fixed Hungarian pluralization
- fixed Belarus pluralization
- completed Croatian translations

## 0.5.1 (2012-03-01)

- pluralization and transliteration work out of the box
- added pluralization rules for non-English-like locales
- added transliteration rule for Russian
- removed translations for will_paginate gem
- brought activemodel and activerecord namespaces back which was removed in 21c8006

## 0.4.0 (2012-02-10)

- removed `activerecord` namespace
- removed `support.select namespace` and updated `helpers.select` when present
- removed the `fun` directory
- added a pluralization rule for French (fr) locale
- replaced pluralization instances of `1` with `%{count}` in French (fr) locale
- modified `datetime.distance_in_words.almost_x_years` for Russian (ru) locale
- changed `number.currency.format.precision` from 3 to 0 for Japanese (ja) locale

## 0.3.0 (2012-01-10)

- loads will_paginate/\*.yml if the constant WillPaginate is defined
- filled in missing will_paginate translations for en-US/en-GB/ja/sk
- Friulian(fur) is ready for Rails 2 and 3
- corrected translation for 'too_short' (ro)
- added will_paginate translation (ro)

## 0.2.1 (2011-12-27)

- filled in missing formatting/punctuation translations with their en-US versions
- added en-IN locale
- changed `time.formats.long` for Japanese (ja)

## 0.2.0 (2011-12-04)

- moved :'activerecord.errors.messages.taken' to :'errors.messages.taken'
- moved :'activerecord.errors.messages.record_invalid'  to :'errors.messages.record_invalid'
- moved Bulgarian (bg) transliterations into a new 'transliterations' folder
- aliased :'activerecord.errors.template' to :'errors.template'
- aliased :'activerecord.errors.messages' to :'errors.messages'
- updated interpolation syntax for Basque (eu)
- updated interpolation syntax for Peruvian Spanish (es-PE)
- deleted translations that are absent from en-US (with the exception of translations for pluralization)
- converted the Czech (cs) localization file to yml
- converted the Thai (th) localization file to yml
- removed the hard coded Buddhist era from the Thai (th) localization file
- fixed obvious indentation/scoping errors
