module CukeModeler

  # A class modeling a comment in a feature file.

  class Comment < Model

    include Parsing
    include Parsed
    include Sourceable


    # The text of the comment
    attr_accessor :text


    # Creates a new Comment object and, if *source_text* is provided, populates the
    # object.
    def initialize(source_text = nil)
      super(source_text)

      if source_text
        parsed_comment_data = parse_source(source_text)
        populate_comment(self, parsed_comment_data)
      end
    end

    # Returns a string representation of this model. For a comment model,
    # this will be Gherkin text that is equivalent to the comment being modeled.
    def to_s
      text || ''
    end


    private


    def parse_source(source_text)
      base_file_string = "\n#{dialect_feature_keyword}: Fake feature to parse"
      source_text = "# language: #{Parsing.dialect}\n" + source_text + base_file_string

      parsed_file = Parsing::parse_text(source_text, 'cuke_modeler_stand_alone_comment.feature')

      parsed_file.first['comments'].last
    end

  end
end
