require "#{File.dirname(__FILE__)}/../spec_helper"


describe 'Outline, Integration' do

  let(:clazz) { CukeModeler::Outline }


  describe 'common behavior' do

    it_should_behave_like 'a model, integration'

  end

  describe 'unique behavior' do

    it 'can be instantiated with the minimum viable Gherkin', :gherkin4 => true do
      source = "#{@outline_keyword}:"

      expect { clazz.new(source) }.to_not raise_error
    end

    it 'can be instantiated with the minimum viable Gherkin', :gherkin2 => true do
      source = "#{@outline_keyword}:"

      expect { clazz.new(source) }.to_not raise_error
    end

    # gherkin 3.x does not accept incomplete outlines
    it 'can be instantiated with the minimum viable Gherkin', :gherkin3 => true do
      source = "#{@outline_keyword}:
                #{@example_keyword}:
                  | param |
                  | value |"

      expect { clazz.new(source) }.to_not raise_error
    end

    it 'can parse text that uses a non-default dialect' do
      original_dialect = CukeModeler::Parsing.dialect
      CukeModeler::Parsing.dialect = 'en-au'

      begin
        source_text = "Reckon it's like: Outline name
                         Yeah nah zen
                         You'll wanna:
                           | param |
                           | value |"

        expect { @model = clazz.new(source_text) }.to_not raise_error

        # Sanity check in case modeling failed in a non-explosive manner
        expect(@model.name).to eq('Outline name')
      ensure
        # Making sure that our changes don't escape a test and ruin the rest of the suite
        CukeModeler::Parsing.dialect = original_dialect
      end
    end

    it 'stores the original data generated by the parsing adapter', :gherkin4 => true do
      outline = clazz.new("@tag\n#{@outline_keyword}: test outline\ndescription\n#{@step_keyword} a step\n#{@example_keyword}:\n|param|\n|value|")
      data = outline.parsing_data

      expect(data.keys).to match_array([:type, :tags, :location, :keyword, :name, :steps, :examples, :description])
      expect(data[:type]).to eq(:ScenarioOutline)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin3 => true do
      outline = clazz.new("@tag\n#{@outline_keyword}: test outline\ndescription\n#{@step_keyword} a step\n#{@example_keyword}:\n|param|\n|value|")
      data = outline.parsing_data

      expect(data.keys).to match_array([:type, :tags, :location, :keyword, :name, :steps, :examples, :description])
      expect(data[:type]).to eq(:ScenarioOutline)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin2 => true do
      outline = clazz.new("@tag\n#{@outline_keyword}: test outline\ndescription\n#{@step_keyword} a step\n#{@example_keyword}:\n|param|\n|value|")
      data = outline.parsing_data

      expect(data.keys).to match_array(['keyword', 'name', 'line', 'description', 'id', 'type', 'examples', 'steps', 'tags'])
      expect(data['keyword']).to eq('Scenario Outline')
    end

    it 'provides a descriptive filename when being parsed from stand alone text' do
      source = "bad outline text \n #{@outline_keyword}:\n #{@step_keyword} a step\n @foo "

      expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_outline\.feature'/)
    end

    it 'properly sets its child models' do
      source = "@a_tag
                  #{@outline_keyword}:
                    #{@step_keyword} a step
                  #{@example_keyword}:
                    | param |
                    | value |"

      outline = clazz.new(source)
      example = outline.examples.first
      step = outline.steps.first
      tag = outline.tags.first

      expect(example.parent_model).to equal(outline)
      expect(step.parent_model).to equal(outline)
      expect(tag.parent_model).to equal(outline)
    end

    describe 'getting ancestors' do

      before(:each) do
        source = "#{@feature_keyword}: Test feature

                    #{@outline_keyword}: Test test
                      #{@step_keyword} a step
                    #{@example_keyword}: Test example
                      | a param |
                      | a value |"

        file_path = "#{@default_file_directory}/outline_test_file.feature"
        File.open(file_path, 'w') { |file| file.write(source) }
      end

      let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
      let(:outline) { directory.feature_files.first.feature.tests.first }


      it 'can get its directory' do
        ancestor = outline.get_ancestor(:directory)

        expect(ancestor).to equal(directory)
      end

      it 'can get its feature file' do
        ancestor = outline.get_ancestor(:feature_file)

        expect(ancestor).to equal(directory.feature_files.first)
      end

      it 'can get its feature' do
        ancestor = outline.get_ancestor(:feature)

        expect(ancestor).to equal(directory.feature_files.first.feature)
      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = outline.get_ancestor(:test)

        expect(ancestor).to be_nil
      end

    end


    describe 'model population' do

      context 'from source text' do

        let(:source_text) { "#{@outline_keyword}:" }
        let(:outline) { clazz.new(source_text) }


        # gherkin 3.x does not accept incomplete outlines
        it "models the outline's keyword", :gherkin3 => false do
          expect(outline.keyword).to eq("#{@outline_keyword}")
        end

        it "models the outline's source line" do
          source_text = "#{@feature_keyword}:

                             #{@outline_keyword}: foo
                               #{@step_keyword} step
                             #{@example_keyword}:
                               | param |
                               | value |"
          outline = CukeModeler::Feature.new(source_text).tests.first

          expect(outline.source_line).to eq(3)
        end


        context 'a filled outline' do

          let(:source_text) { "@tag1 @tag2 @tag3
                                 #{@outline_keyword}: Foo
                                     Scenario description.

                                   Some more.
                                       Even more.

                                   #{@step_keyword} a <setup> step
                                   #{@step_keyword} an action step
                                   #{@step_keyword} a <verification> step

                                 #{@example_keyword}: example 1
                                   | setup | verification |
                                   | x     | y            |
                                 #{@example_keyword}: example 2
                                   | setup | verification |
                                   | a     | b            |" }
          let(:outline) { clazz.new(source_text) }


          it "models the outline's name" do
            expect(outline.name).to eq('Foo')
          end

          it "models the outline's description" do
            description = outline.description.split("\n", -1)

            expect(description).to eq(['  Scenario description.',
                                       '',
                                       'Some more.',
                                       '    Even more.'])
          end

          it "models the outline's steps" do
            step_names = outline.steps.collect { |step| step.text }

            expect(step_names).to eq(['a <setup> step', 'an action step', 'a <verification> step'])
          end

          it "models the outline's tags" do
            tag_names = outline.tags.collect { |tag| tag.name }

            expect(tag_names).to eq(['@tag1', '@tag2', '@tag3'])
          end

          it "models the outline's examples" do
            example_names = outline.examples.collect { |example| example.name }

            expect(example_names).to eq(['example 1', 'example 2'])
          end

        end


        # gherkin 3.x does not accept incomplete outlines
        context 'an empty outline', :gherkin3 => false do

          let(:source_text) { "#{@outline_keyword}:" }
          let(:outline) { clazz.new(source_text) }


          it "models the outline's name" do
            expect(outline.name).to eq('')
          end

          it "models the outline's description" do
            expect(outline.description).to eq('')
          end

          it "models the outline's steps" do
            expect(outline.steps).to eq([])
          end

          it "models the outline's tags" do
            expect(outline.tags).to eq([])
          end

          it "models the outline's examples" do
            expect(outline.examples).to eq([])
          end

        end

      end

    end

    it 'trims whitespace from its source description' do
      source = ["#{@outline_keyword}:",
                '  ',
                '        description line 1',
                '',
                '   description line 2',
                '     description line 3               ',
                '',
                '',
                '',
                "  #{@step_keyword} a step",
                '',
                "#{@example_keyword}:",
                '|param|',
                '|value|']
      source = source.join("\n")

      outline = clazz.new(source)
      description = outline.description.split("\n", -1)

      expect(description).to eq(['     description line 1',
                                 '',
                                 'description line 2',
                                 '  description line 3'])
    end


    describe 'comparison' do

      it 'is equal to a background with the same steps' do
        source = "#{@outline_keyword}:
                      #{@step_keyword} step 1
                      #{@step_keyword} step 2
                    #{@example_keyword}:
                      | param |
                      | value |"
        outline = clazz.new(source)

        source = "#{@background_keyword}:
                      #{@step_keyword} step 1
                      #{@step_keyword} step 2"
        background_1 = CukeModeler::Background.new(source)

        source = "#{@background_keyword}:
                      #{@step_keyword} step 2
                      #{@step_keyword} step 1"
        background_2 = CukeModeler::Background.new(source)


        expect(outline).to eq(background_1)
        expect(outline).to_not eq(background_2)
      end

      it 'is equal to a scenario with the same steps' do
        source = "#{@outline_keyword}:
                      #{@step_keyword} step 1
                      #{@step_keyword} step 2
                    #{@example_keyword}:
                      | param |
                      | value |"
        outline = clazz.new(source)

        source = "#{@scenario_keyword}:
                      #{@step_keyword} step 1
                      #{@step_keyword} step 2"
        scenario_1 = CukeModeler::Scenario.new(source)

        source = "#{@scenario_keyword}:
                      #{@step_keyword} step 2
                      #{@step_keyword} step 1"
        scenario_2 = CukeModeler::Scenario.new(source)


        expect(outline).to eq(scenario_1)
        expect(outline).to_not eq(scenario_2)
      end

      it 'is equal to an outline with the same steps' do
        source = "#{@outline_keyword}:
                      #{@step_keyword} step 1
                      #{@step_keyword} step 2
                    #{@example_keyword}:
                      | param |
                      | value |"
        outline_1 = clazz.new(source)

        source = "#{@outline_keyword}:
                      #{@step_keyword} step 1
                      #{@step_keyword} step 2
                    #{@example_keyword}:
                      | param |
                      | value |"
        outline_2 = clazz.new(source)

        source = "#{@outline_keyword}:
                      #{@step_keyword} step 2
                      #{@step_keyword} step 1
                    #{@example_keyword}:
                      | param |
                      | value |"
        outline_3 = clazz.new(source)


        expect(outline_1).to eq(outline_2)
        expect(outline_1).to_not eq(outline_3)
      end

    end


    describe 'outline output' do

      it 'can be remade from its own output' do
        source = "@tag1 @tag2 @tag3
                  #{@outline_keyword}: An outline with everything it could have

                  Some description.
                  Some more description.

                    #{@step_keyword} a step
                      | value |
                    #{@step_keyword} a <value> step
                      \"\"\"
                        some string
                      \"\"\"

        #{@example_keyword}:

                  Some description.
                  Some more description.

                    | value |
                    | x     |

                  @example_tag
                  #{@example_keyword}:
                    | value |
                    | y     |"
        outline = clazz.new(source)

        outline_output = outline.to_s
        remade_outline_output = clazz.new(outline_output).to_s

        expect(remade_outline_output).to eq(outline_output)
      end


      context 'from source text' do

        # gherkin 3.x does not accept incomplete outlines
        it 'can output an empty outline', :gherkin3 => false do
          source = ["#{@outline_keyword}:"]
          source = source.join("\n")
          outline = clazz.new(source)

          outline_output = outline.to_s.split("\n", -1)

          expect(outline_output).to eq(["#{@outline_keyword}:"])
        end

        # gherkin 3.x does not accept incomplete outlines
        it 'can output a outline that has a name', :gherkin3 => false do
          source = ["#{@outline_keyword}: test outline"]
          source = source.join("\n")
          outline = clazz.new(source)

          outline_output = outline.to_s.split("\n", -1)

          expect(outline_output).to eq(["#{@outline_keyword}: test outline"])
        end

        # gherkin 3.x does not accept incomplete outlines
        it 'can output a outline that has a description', :gherkin3 => false do
          source = ["#{@outline_keyword}:",
                    'Some description.',
                    'Some more description.']
          source = source.join("\n")
          outline = clazz.new(source)

          outline_output = outline.to_s.split("\n", -1)

          expect(outline_output).to eq(["#{@outline_keyword}:",
                                        '',
                                        'Some description.',
                                        'Some more description.'])
        end

        # gherkin 3.x does not accept incomplete outlines
        it 'can output a outline that has steps', :gherkin3 => false do
          source = ["#{@outline_keyword}:",
                    "  #{@step_keyword} a step",
                    '    | value |',
                    "  #{@step_keyword} another step",
                    '    """',
                    '    some string',
                    '    """']
          source = source.join("\n")
          outline = clazz.new(source)

          outline_output = outline.to_s.split("\n", -1)

          expect(outline_output).to eq(["#{@outline_keyword}:",
                                        "  #{@step_keyword} a step",
                                        '    | value |',
                                        "  #{@step_keyword} another step",
                                        '    """',
                                        '    some string',
                                        '    """'])
        end

        # gherkin 3.x does not accept incomplete outlines
        it 'can output a outline that has tags', :gherkin3 => false do
          source = ['@tag1 @tag2',
                    '@tag3',
                    "#{@outline_keyword}:"]
          source = source.join("\n")
          outline = clazz.new(source)

          outline_output = outline.to_s.split("\n", -1)

          expect(outline_output).to eq(['@tag1 @tag2 @tag3',
                                        "#{@outline_keyword}:"])
        end

        it 'can output a outline that has examples' do
          source = ["#{@outline_keyword}:",
                    "#{@step_keyword} a step",
                    "#{@example_keyword}:",
                    '| value |',
                    '| x     |',
                    "#{@example_keyword}:",
                    '| value |',
                    '| y     |']
          source = source.join("\n")
          outline = clazz.new(source)

          outline_output = outline.to_s.split("\n", -1)

          expect(outline_output).to eq(["#{@outline_keyword}:",
                                        "  #{@step_keyword} a step",
                                        '',
                                        "#{@example_keyword}:",
                                        '  | value |',
                                        '  | x     |',
                                        '',
                                        "#{@example_keyword}:",
                                        '  | value |',
                                        '  | y     |'])
        end

        it 'can output a outline that has everything' do
          source = ['@tag1 @tag2 @tag3',
                    "#{@outline_keyword}: A outline with everything it could have",
                    'Including a description',
                    'and then some.',
                    "#{@step_keyword} a step",
                    '|value|',
                    "#{@step_keyword} another step",
                    '"""',
                    'some string',
                    '"""',
                    '',
                    "#{@example_keyword}:",
                    '',
                    'Some description.',
                    'Some more description.',
                    '',
                    '| value |',
                    '| x     |',
                    '',
                    '@example_tag',
                    "#{@example_keyword}:",
                    '| value |',
                    '| y     |']
          source = source.join("\n")
          outline = clazz.new(source)

          outline_output = outline.to_s.split("\n", -1)

          expect(outline_output).to eq(['@tag1 @tag2 @tag3',
                                        "#{@outline_keyword}: A outline with everything it could have",
                                        '',
                                        'Including a description',
                                        'and then some.',
                                        '',
                                        "  #{@step_keyword} a step",
                                        '    | value |',
                                        "  #{@step_keyword} another step",
                                        '    """',
                                        '    some string',
                                        '    """',
                                        '',
                                        "#{@example_keyword}:",
                                        '',
                                        'Some description.',
                                        'Some more description.',
                                        '',
                                        '  | value |',
                                        '  | x     |',
                                        '',
                                        '@example_tag',
                                        "#{@example_keyword}:",
                                        '  | value |',
                                        '  | y     |'])
        end

      end


      context 'from abstract instantiation' do

        let(:outline) { clazz.new }


        it 'can output an outline that has only tags' do
          outline.tags = [CukeModeler::Tag.new]

          expect { outline.to_s }.to_not raise_error
        end

        it 'can output an outline that has only steps' do
          outline.steps = [CukeModeler::Step.new]

          expect { outline.to_s }.to_not raise_error
        end

        it 'can output an outline that has only examples' do
          outline.examples = [CukeModeler::Example.new]

          expect { outline.to_s }.to_not raise_error
        end

      end

    end

  end

end
