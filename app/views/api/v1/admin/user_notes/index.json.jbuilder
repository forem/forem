json.notes(@notes) do |note|
  json.partial!("api/v1/admin/user_notes/note", note: note)
end
