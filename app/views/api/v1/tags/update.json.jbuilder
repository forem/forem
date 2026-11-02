# The GET /api/tags fields plus every field this endpoint can edit
json.extract!(@tag, :id, :name, :pretty_name, :short_summary, :supported, :wiki_body_markdown,
              :context_note_instructions, :bg_color_hex, :text_color_hex)
