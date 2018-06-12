class ReplitTag < LiquidTagBase
  def initialize(tag_name, id, tokens)
    super
    @id = parse_id(id)
  end

  def render(context)
    '<div class="ltag__replit">
      <iframe frameborder="0" height="550px" src="https://repl.it/'+@id+'?lite=true"></iframe>
    </div>'
  end

  private

  def parse_id(input)
    input_no_space = input.delete(' ')
    if valid_id?(input_no_space)
      input_no_space
    else
      raise StandardError, 'Invalid repl.it Id'
    end
  end

  def valid_id?(id)
    id.length > 1 && !(id !~ /[a-zA-Z0-9\/]/)
  end
end

Liquid::Template.register_tag("replit", ReplitTag)
