# frozen_string_literal: true

require 'pp' # fixes fakefs weirdness
require 'fakefs/spec_helpers'
require 'stringio'

require 'koota/cli'

RSpec.describe Koota::CLI do
  include FakeFS::SpecHelpers

  USAGE_MSG = 'usage: koota [options] FILE ...'

  let(:output) { StringIO.new(''.dup) }
  let(:cli) { described_class.new(program_name: 'koota', output: output) }

  describe '#call' do
    context 'given -h or --help' do
      it 'shows help', :aggregate_failures do
        expect(cli.call(['-h'])).to eq(true)
        expect(output.string).to include(USAGE_MSG)

        output.string = ''.dup
        expect(cli.call(['--help'])).to eq(true)
        expect(output.string).to include(USAGE_MSG)
      end

      it 'overrides all other options' do
        expect(cli.call(['-v', '-h'])).to eq(true)
        expect(output.string).to include(USAGE_MSG)
      end
    end

    context 'given -v or --version' do
      it 'shows the version' do
        expect(cli.call(['-v'])).to eq(true)
        expect(output.string).to include("koota v#{Koota::VERSION}")
      end
    end

    context 'given nothing' do
      it 'complains' do
        expect(cli.call([])).to eq(false)
        expect(output.string).to include('error: missing input file(s)')
      end

      it 'shows help' do
        expect(cli.call([])).to eq(false)
        expect(output.string).to include(USAGE_MSG)
      end
    end

    context 'given one file' do
      context 'and it exists' do
        it 'processes it' do
          File.write('test.koota', 'abc')
          expect(cli.call(['test.koota'])).to eq(true)
          expect(output.string).to eq("abc\n")
        end
      end
    end

    context 'given files' do
      context 'and every one exists' do
        it 'processes each in turn' do
          File.write('test1.koota', 'abc')
          File.write('test2.koota', 'def')
          File.write('test3.koota', 'ghi')

          expect(cli.call(['test1.koota', 'test2.koota', 'test3.koota'])).to eq(true)
          expect(output.string).to eq(<<~OUTPUT)
            --- test1.koota
            abc

            --- test2.koota
            def

            --- test3.koota
            ghi
          OUTPUT
        end
      end

      context 'and a file does not exist' do
        let(:result) do
          File.write('test1.koota', 'abc')
          cli.call(['test1.koota', 'test2.koota', 'test3.koota'])
        end

        it 'complains about non existent files' do
          expect(result).to eq(false)
          expect(output.string).to include("error: could not find file 'test2.koota'")
            .and include("error: could not find file 'test3.koota'")
        end
      end

      it 'takes all the cool options' do
        File.write('test1.koota', 'a/b')
        result = cli.call(%w[-d -s 1,2 -w 10 -r . -p ; test1.koota])

        expect(result).to eq(true)

        # match like 'a;a.b;b;b.a;b.b;a;b.a;b;a;b.b'
        expect(output.string).to match(/\A(?:[ab](?:\.[ab])?;){9}(?:[ab](?:\.[ab])?)\n\z/)
      end
    end
  end
end
