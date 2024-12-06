require_relative "safely/core"

Object.include Safely::Methods
Object.send :private, :safely, :yolo
