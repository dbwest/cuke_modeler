require 'spec_helper'

SimpleCov.command_name('Background') unless RUBY_VERSION.to_s < '1.9.0'

describe 'Background, Integration' do

  let(:clazz) { CukeModeler::Background }


  describe 'common behavior' do

    it_should_behave_like 'a modeled element, integration'

  end

  describe 'unique behavior' do

    it 'properly sets its child elements' do
      source = ['  Background: Test background',
                '    * a step']
      source = source.join("\n")

      background = clazz.new(source)
      step = background.steps.first

      expect(step.parent_model).to equal(background)
    end

    describe 'getting ancestors' do

      before(:each) do
        source = ['Feature: Test feature',
                  '',
                  '  Background: Test background',
                  '    * a step:']
        source = source.join("\n")

        file_path = "#{@default_file_directory}/background_test_file.feature"
        File.open(file_path, 'w') { |file| file.write(source) }
      end

      let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
      let(:background) { directory.feature_files.first.feature.background }


      it 'can get its directory' do
        ancestor = background.get_ancestor(:directory)

        expect(ancestor).to equal(directory)
      end

      it 'can get its feature file' do
        ancestor = background.get_ancestor(:feature_file)

        expect(ancestor).to equal(directory.feature_files.first)
      end

      it 'can get its feature' do
        ancestor = background.get_ancestor(:feature)

        expect(ancestor).to equal(directory.feature_files.first.feature)
      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = background.get_ancestor(:example)

        expect(ancestor).to be_nil
      end

    end


    describe 'model population' do

      context 'from source text' do

        it "models the background's source line" do
          source_text = "Feature:

                           Background: foo
                             * step"
          background = CukeModeler::Feature.new(source_text).background

          expect(background.source_line).to eq(3)
        end

        context 'a filled background' do

          let(:source_text) { "Background:
                                 * a step
                                 * another step" }
          let(:background) { clazz.new(source_text) }


          it "models the background's steps" do
            step_names = background.steps.collect { |step| step.base }

            expect(step_names).to eq(['a step', 'another step'])
          end

        end

        context 'an empty background' do

          let(:source_text) { 'Background:' }
          let(:background) { clazz.new(source_text) }


          it "models the background's steps" do
            expect(background.steps).to eq([])
          end

        end

      end

    end


    describe 'comparison' do

      it 'is equal to a background with the same steps' do
        source = "Background:
                    * step 1
                    * step 2"
        background_1 = clazz.new(source)

        source = "Background:
                    * step 1
                    * step 2"
        background_2 = clazz.new(source)

        source = "Background:
                    * step 2
                    * step 1"
        background_3 = clazz.new(source)


        expect(background_1).to eq(background_2)
        expect(background_1).to_not eq(background_3)
      end

      it 'is equal to a scenario with the same steps' do
        source = "Background:
                    * step 1
                    * step 2"
        background = clazz.new(source)

        source = "Scenario:
                    * step 1
                    * step 2"
        scenario_1 = CukeModeler::Scenario.new(source)

        source = "Scenario:
                    * step 2
                    * step 1"
        scenario_2 = CukeModeler::Scenario.new(source)


        expect(background).to eq(scenario_1)
        expect(background).to_not eq(scenario_2)
      end

      it 'is equal to an outline with the same steps' do
        source = "Background:
                    * step 1
                    * step 2"
        background = clazz.new(source)

        source = "Scenario Outline:
                    * step 1
                    * step 2
                  Examples:
                    | param |
                    | value |"
        outline_1 = CukeModeler::Outline.new(source)

        source = "Scenario Outline:
                    * step 2
                    * step 1
                  Examples:
                    | param |
                    | value |"
        outline_2 = CukeModeler::Outline.new(source)


        expect(background).to eq(outline_1)
        expect(background).to_not eq(outline_2)
      end

    end


    describe 'background output' do

      it 'can be remade from its own output' do
        source = ['Background: A background with everything it could have',
                  '',
                  'Including a description',
                  'and then some.',
                  '',
                  '  * a step',
                  '    | value |',
                  '  * another step',
                  '    """',
                  '    some string',
                  '    """']
        source = source.join("\n")
        background = clazz.new(source)

        background_output = background.to_s
        remade_background_output = clazz.new(background_output).to_s

        expect(remade_background_output).to eq(background_output)
      end


      context 'from source text' do

        it 'can output a background that has steps' do
          source = ['Background:',
                    '* a step',
                    '|value|',
                    '* another step',
                    '"""',
                    'some string',
                    '"""']
          source = source.join("\n")
          background = clazz.new(source)

          background_output = background.to_s.split("\n")

          expect(background_output).to eq(['Background:',
                                           '  * a step',
                                           '    | value |',
                                           '  * another step',
                                           '    """',
                                           '    some string',
                                           '    """'])
        end

        it 'can output a background that has everything' do
          source = ['Background: A background with everything it could have',
                    'Including a description',
                    'and then some.',
                    '* a step',
                    '|value|',
                    '* another step',
                    '"""',
                    'some string',
                    '"""']
          source = source.join("\n")
          background = clazz.new(source)

          background_output = background.to_s.split("\n")

          expect(background_output).to eq(['Background: A background with everything it could have',
                                           '',
                                           'Including a description',
                                           'and then some.',
                                           '',
                                           '  * a step',
                                           '    | value |',
                                           '  * another step',
                                           '    """',
                                           '    some string',
                                           '    """'])
        end

      end


      context 'from abstract instantiation' do

        let(:background) { clazz.new }


        it 'can output a background that has only steps' do
          background.steps = [CukeModeler::Step.new]

          expect { background.to_s }.to_not raise_error
        end

      end

    end

  end

end
