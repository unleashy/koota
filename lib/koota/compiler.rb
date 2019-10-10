# frozen_string_literal: true

require 'koota/encode'
require 'koota/decode'
require 'koota/vm'

module Koota
  # Compiles an AST as returned by {Koota::Parser#call} into bytecode to be
  # consumed by {Koota::VM#call}.
  class Compiler
    include Koota::VM::Opcodes

    def call(ast, refs = {})
      @memory = []
      @refs   = refs
      @links  = {
        calls: {},
        picks: {}
      }

      compile(ast)

      (@memory << HALT).tap do
        link_calls(@links[:calls])
        link_picks(@links[:picks])
      end
    end

    def link_calls(links)
      return if links.empty?

      offsets = {}

      # Compile referred ASTs, storing their start offset. Only compile those
      # that are referenced by a link.
      @refs.each do |ref, ref_ast|
        next unless links.value?(ref)

        offsets[ref] = @memory.length
        compile(ref_ast)
        add_bytecode(RET) # Close off with a ret since they are subroutines after all
      end

      # And link everything!
      links.each do |offset, ref|
        @memory[offset + 1], @memory[offset + 2] = Encode.short(offsets[ref])
      end
    end

    def link_picks(links)
      return if links.empty?

      links.each do |offset, picks|
        # Replace the placeholder with the real offset.
        @memory[offset + 1], @memory[offset + 2] = Encode.short(@memory.length)

        # Now just output the length and the picks' offsets.
        add_bytecode(*Encode.short(picks.length))
        picks.each do |pick|
          add_bytecode(*Encode.short(pick))
        end
      end
    end

    def compile_pattern(*sequence)
      sequence.each { |it| compile(it) }
    end

    def compile_choice(*choices)
      # First of all, we need to emit a pick opcode. The offset to the pick
      # list is a placeholder for the same reasons calls use placeholders.
      pick_offset = @memory.length
      add_bytecode(PICK, 0, 0)

      # We now loop through each choice and compile it. We also add a jump to
      # the end of the "choice area" after each choice (except the last, since
      # it's just gonna be a jump into the next opcode) in order to skip the
      # rest of the choices. The jumps use a placeholder too, which will be
      # linked after the loop using the `jumps` array.
      jumps   = []
      offsets = []
      choices.each_with_index do |choice, i|
        # We need the offset for each choice for the pick list.
        offsets << @memory.length
        compile(choice)

        # The last choice doesn't need a jump, since it's just gonna be a jump
        # to the next opcode.
        unless i == choices.length - 1
          jumps << @memory.length
          add_bytecode(JUMP, 0, 0)
        end
      end

      # Link the jumps.
      encoded_jump = Encode.short(@memory.length)
      jumps.each do |offset|
        @memory[offset + 1], @memory[offset + 2] = encoded_jump
      end

      # Add the pick offset and the choice offsets to the pick links to be
      # processed later, in `link_picks`.
      @links[:picks][pick_offset] = offsets
    end

    def compile_maybe(maybe)
      # A maybe is compiled down to a jrnd pointing after its contents. We can
      # link the offset immediately since we know the length of the maybe.
      jrnd_offset = @memory.length
      add_bytecode(JRND, 0, 0)

      compile(maybe)

      @memory[jrnd_offset + 1], @memory[jrnd_offset + 2] = Encode.short(@memory.length)
    end

    def compile_atom(atom)
      atom.each_char do |char|
        if @refs[char.to_sym]
          # This will be linked to the real offset in a later stage (aka
          # `link_calls`). For now, we use zero as a placeholder and store the
          # current offset in `@links`. This is needed because we don't know
          # what offset to use before all the code is compiled.
          @links[:calls][@memory.length] = char.to_sym
          add_bytecode(CALL, 0, 0)
        else
          add_bytecode(PUT, *Encode.utf8(char))
        end
      end
    end

    def compile_raw(raw)
      raw.each_char do |char|
        add_bytecode(PUT, *Encode.utf8(char))
      end
    end

    private

    def add_bytecode(*bytecode)
      @memory.concat(bytecode)
    end

    def compile(ast)
      raise ArgumentError, 'invalid AST' if ast.empty?

      send(:"compile_#{ast[0]}", *ast[1..-1])
    end
  end
end
