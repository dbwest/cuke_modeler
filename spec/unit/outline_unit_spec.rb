require 'spec_helper'

SimpleCov.command_name('Outline') unless RUBY_VERSION.to_s < '1.9.0'

describe 'Outline, Unit' do

  let(:clazz) { CukeModeler::Outline }
  let(:outline) { clazz.new }


  describe 'common behavior' do

    it_should_behave_like 'a modeled element'
    it_should_behave_like 'a named element'
    it_should_behave_like 'a described element'
    it_should_behave_like 'a stepped element'
    it_should_behave_like 'a tagged element'
    it_should_behave_like 'a sourced element'
    it_should_behave_like 'a raw element'

  end


  describe 'unique behavior' do

    it 'can be parsed from stand alone text' do
      source = "Scenario Outline: test outline
              Examples:
                |param|
                |value|"

      expect { @element = clazz.new(source) }.to_not raise_error

      # Sanity check in case instantiation failed in a non-explosive manner
      @element.name.should == 'test outline'
    end

    it 'provides a descriptive filename when being parsed from stand alone text' do
      source = "bad outline text \n Scenario Outline:\n And a step\n @foo "

      expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_outline\.feature'/)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin4 => true do
      outline = clazz.new("Scenario Outline: test outline\nExamples:\n|param|\n|value|")
      raw_data = outline.raw_element

      expect(raw_data.keys).to match_array([:type, :tags, :location, :keyword, :name, :steps, :examples])
      expect(raw_data[:type]).to eq(:ScenarioOutline)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin3 => true do
      outline = clazz.new("Scenario Outline: test outline\nExamples:\n|param|\n|value|")
      raw_data = outline.raw_element

      expect(raw_data.keys).to match_array([:type, :tags, :location, :keyword, :name, :steps, :examples])
      expect(raw_data[:type]).to eq(:ScenarioOutline)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin2 => true do
      outline = clazz.new("Scenario Outline: test outline\nExamples:\n|param|\n|value|")
      raw_data = outline.raw_element

      expect(raw_data.keys).to match_array(['keyword', 'name', 'line', 'description', 'id', 'type'])
      expect(raw_data['keyword']).to eq('Scenario Outline')
    end

    it 'has examples' do
      outline.should respond_to(:examples)
    end

    it 'can change its examples' do
      expect(outline).to respond_to(:examples=)

      outline.examples = :some_examples
      outline.examples.should == :some_examples
      outline.examples = :some_other_examples
      outline.examples.should == :some_other_examples
    end


    describe 'abstract instantiation' do

      context 'a new outline object' do

        let(:outline) { clazz.new }


        it 'starts with no examples' do
          expect(outline.examples).to eq([])
        end

      end

    end
    
    it 'contains steps, examples, and tags' do
      tags = [:tag_1, :tagt_2]
      steps = [:step_1, :step_2, :step_3]
      examples = [:example_1, :example_2, :example_3]
      everything = steps + examples + tags

      outline.steps = steps
      outline.examples = examples
      outline.tags = tags

      expect(outline.children).to match_array(everything)
    end


    describe 'comparison' do

      it 'can gracefully be compared to other types of objects' do
        # Some common types of object
        [1, 'foo', :bar, [], {}].each do |thing|
          expect { outline == thing }.to_not raise_error
          expect(outline == thing).to be false
        end
      end

    end


    describe 'outline output edge cases' do

      it 'is a String' do
        outline.to_s.should be_a(String)
      end


      context 'a new outline object' do

        let(:outline) { clazz.new }


        it 'can output an empty outline' do
          expect { outline.to_s }.to_not raise_error
        end

        it 'can output an outline that has only a name' do
          outline.name = 'a name'

          expect { outline.to_s }.to_not raise_error
        end

        it 'can output an outline that has only a description' do
          outline.description = 'a description'

          expect { outline.to_s }.to_not raise_error
        end

      end

    end

  end

end
