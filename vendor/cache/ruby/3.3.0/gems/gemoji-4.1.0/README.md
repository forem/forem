gemoji
======

This library contains character information about native emojis.


Installation
------------

Add `gemoji` to your Gemfile.

``` ruby
gem 'gemoji'
```


Example Rails Helper
--------------------

This would allow emojifying content such as: `it's raining :cat:s and :dog:s!`

See the [Emoji cheat sheet](http://www.emoji-cheat-sheet.com) for more examples.

```ruby
module EmojiHelper
  def emojify(content)
    h(content).to_str.gsub(/:([\w+-]+):/) do |match|
      if emoji = Emoji.find_by_alias($1)
        %(<img alt="#$1" src="#{image_path("emoji/#{emoji.image_filename}")}" style="vertical-align:middle" width="20" height="20" />)
      else
        match
      end
    end.html_safe if content.present?
  end
end
```

Unicode mapping
---------------

Translate emoji names to unicode and vice versa.

```ruby
>> Emoji.find_by_alias("cat").raw
=> "🐱"  # Don't see a cat? That's U+1F431.

>> Emoji.find_by_unicode("\u{1f431}").name
=> "cat"
```

Adding new emoji
----------------

You can add new emoji characters to the `Emoji.all` list:

```ruby
emoji = Emoji.create("music") do |char|
  char.add_alias "song"
  char.add_unicode_alias "\u{266b}"
  char.add_tag "notes"
end

emoji.name #=> "music"
emoji.raw  #=> "♫"
emoji.image_filename #=> "unicode/266b.png"

# Creating custom emoji (no Unicode aliases):
emoji = Emoji.create("music") do |char|
  char.add_tag "notes"
end

emoji.custom? #=> true
emoji.image_filename #=> "music.png"
```

As you create new emoji, you must ensure that you also create and put the images
they reference by their `image_filename` to your assets directory.

You can customize `image_filename` with:

```ruby
emoji = Emoji.create("music") do |char|
  char.image_filename = "subdirectory/my_emoji.gif"
end
```

For existing emojis, you can edit the list of aliases or add new tags in an edit block:

```ruby
emoji = Emoji.find_by_alias "musical_note"

Emoji.edit_emoji(emoji) do |char|
  char.add_alias "music"
  char.add_unicode_alias "\u{266b}"
  char.add_tag "notes"
end

Emoji.find_by_alias "music"       #=> emoji
Emoji.find_by_unicode "\u{266b}"  #=> emoji
```
