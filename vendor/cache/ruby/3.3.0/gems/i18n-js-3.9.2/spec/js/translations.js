
;(function(){
  var generator = function() {
    var Translations = {};

    Translations.en = {
        hello: "Hello World!"
      , paid: "You were paid %{price}"

      , paid_with_vat: "You were paid %{price} (incl. VAT %{vat})"

      , booleans: {
          yes: true,
          no: false
        }

      , greetings: {
            stranger: "Hello stranger!"
          , name: "Hello {{name}}!"
        }

      , profile: {
          details: "{{name}} is {{age}}-years old"
        }

      , inbox: {
            one: "You have {{count}} message"
          , other: "You have {{count}} messages"
          , zero: "You have no messages"
        }

      , sent: {
            one: null
          , other: null
          , zero: null
        }

      , unread: {
            one: "You have 1 new message ({{unread}} unread)"
          , other: "You have {{count}} new messages ({{unread}} unread)"
          , zero: "You have no new messages ({{unread}} unread)"
        }

      , number: {
          human: {
            storage_units: {
                units: {
                  "byte": {
                      one: "Byte"
                    , other: "Bytes"
                  }
                , "kb": "KB"
                , "mb": "MB"
                , "gb": "GB"
                , "tb": "TB"
              }
            }
          }
        }

      , extended: {
          number: {
            human: {
              storage_units: {
                  units: {
                    "mb": "Megabyte"
                }
              }
            }
          }
        }

      , arrayWithParams: [
        null,
        "An item with a param of {{value}}",
        "Another item with a param of {{value}}",
        "A last item with a param of {{value}}",
        ["An", "array", "of", "strings"],
        {foo: "bar"}
      ]

      , null_key: null,

      sentences_with_dots: {
          "A implies B means something.": "A implies B means that when A is true, B must be true."
      }
    };

    Translations["en-US"] = {
      date: {
          formats: {
              "default": "%d/%m/%Y"
            , "short": "%d de %B"
            , "long": "%d de %B de %Y"
          }

        , day_names: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        , abbr_day_names: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        , month_names: [null, "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        , abbr_month_names: [null, "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sept", "Oct", "Nov", "Dec"]
        , meridian: ["am", "pm"]
      }
    };

    Translations["pt-BR"] = {
        hello: "Olá Mundo!"

      , number: {
          currency: {
            format: {
              delimiter: ".",
              format: "%u %n",
              precision: 2,
              separator: ",",
              unit: "R$"
            }
          }
          , percentage: {
            format: {
                delimiter: ""
              , separator: ","
              , precision: 2
            }
          }
        }

      , date: {
          formats: {
              "default": "%d/%m/%Y"
            , "short": "%d de %B"
            , "long": "%d de %B de %Y"
            , "short_with_placeholders": "%d de %B {{p1}} {{p2}}"
          }
          , day_names: ["Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"]
          , abbr_day_names: ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
          , month_names: [null, "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
          , abbr_month_names: [null, "Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"]
        }

      , time: {
            formats: {
                "default": "%A, %d de %B de %Y, %H:%M h"
              , "short": "%d/%m, %H:%M h"
              , "long": "%A, %d de %B de %Y, %H:%M h"
              , "short_with_placeholders": "%d/%m, %H:%M h {{p1}}"
            }
          , am: "AM"
          , pm: "PM"
        }
    };

    Translations["de"] = {
        hello: "Hallo Welt!"
      , date: {
          day_names: ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]
        }

      , time: {
            am: "de:AM"
          , pm: "de:PM"
        }
    };

    Translations["nb"] = {
      hello: "Hei Verden!"
    };

    Translations["zh-Hant"] = {
        cat: "貓"
      , dragon: "龍"
    };

    Translations["zh"] = {
        dog: "狗"
      , dragon: "龙"
    };

    return Translations;
  };

  if (typeof define === 'function' && define.amd) {
    define(function() { return generator; });
  } else if (typeof(exports) === "undefined") {
    window.Translations = generator;
  } else {
    module.exports = generator;
  }
})();
