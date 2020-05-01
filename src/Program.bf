using System;
using System.IO;
using System.Collections;

namespace Brainfuck
{
	class Program
	{
		public static void Main(String[] arg)
		{
			if (arg.Count < 1)
			{
				Console.WriteLine("Usage: Brainfuck <filepath> [bufferSize=30000]");
				return;
			}
			var bufferSize = 30000;
			if (arg.Count == 2)
			{
				switch (int.Parse(arg[1]))
				{
				case .Err(let err):
					Console.WriteLine(err);
					return;
				case .Ok(let value):
					bufferSize = value;
				}
			}
			var fileContent = new String;
			switch (File.ReadAllText(arg[0], fileContent))
			{
			case .Err(let err):
				Console.WriteLine("Error reading file: {}", err);
				delete fileContent;
				return;
			default:
				break;
			}

			let prog = new BrainfuckProgram(bufferSize, fileContent);
			delete fileContent;
			prog.Exec();
			delete prog;
		}
	}

	class BrainfuckProgram
	{
		public int pointerPosition = 0;
		public char8[] buffer ~ delete _;
		private Instruction[] instructions ~ delete _;
		private IncrementPointerInstruction incrementPointerInstruction = new IncrementPointerInstruction(this) ~ delete _;
		private DecrementPointerInstruction decrementPointerInstruction = new DecrementPointerInstruction(this) ~ delete _;
		private IncrementInstruction incrementInstruction = new IncrementInstruction(this) ~ delete _;
		private DecrementInstruction decrementInstruction = new DecrementInstruction(this) ~ delete _;
		private PrintInstruction printInstruction = new PrintInstruction(this) ~ delete _;
		private InputInstruction inputInstruction = new InputInstruction(this) ~ delete _;
		private WhileInstruction[] whileInstructions ~ delete _;

		public this(int bufferSize, String program)
		{
			this.buffer = new char8[bufferSize];

			this.ParseProgram(program);
		}

		public ~this()
		{
			for (var i = 0; i < this.whileInstructions.Count; i++)
			{
				delete this.whileInstructions[i];
			}
		}

		private void ParseProgram(String program)
		{
			let instructionsList = new List<List<Instruction>>;
			instructionsList.Add(new List<Instruction>);
			let whileInstructionList = new List<WhileInstruction>;
			for (var i = 0; i < program.Length; i++)
			{
				switch (program[i])
				{
				case '>':
					instructionsList[instructionsList.Count - 1].Add(incrementPointerInstruction);
					break;
				case '<':
					instructionsList[instructionsList.Count - 1].Add(decrementPointerInstruction);
					break;
				case '+':
					instructionsList[instructionsList.Count - 1].Add(incrementInstruction);
					break;
				case '-':
					instructionsList[instructionsList.Count - 1].Add(decrementInstruction);
					break;
				case '[':
					instructionsList.Add(new List<Instruction>);
					break;
				case ']':
					let whileInstructions = instructionsList.PopBack();
					let instructionsArray = new Instruction[whileInstructions.Count];
					whileInstructions.CopyTo(instructionsArray);
					delete whileInstructions;
					let whileInstruction = new WhileInstruction(this, instructionsArray);
					whileInstructionList.Add(whileInstruction);
					instructionsList[instructionsList.Count - 1].Add(whileInstruction);
					break;
				case '.':
					instructionsList[instructionsList.Count - 1].Add(printInstruction);
					break;
				case ',':
					instructionsList[instructionsList.Count - 1].Add(inputInstruction);
					break;
				}
			}
			let instructions = instructionsList.PopBack();
			let instructionsArray = new Instruction[instructions.Count];
			instructions.CopyTo(instructionsArray);
			this.instructions = instructionsArray;
			delete instructions;
			delete instructionsList;

			let whileInstructions = new WhileInstruction[whileInstructionList.Count];
			whileInstructionList.CopyTo(whileInstructions);
			delete whileInstructionList;
			this.whileInstructions = whileInstructions;
		}

		public void Exec()
		{
			for (var i = 0; i < this.instructions.Count; i++)
			{
				this.instructions[i].Exec();
			}
		}
	}

	interface Instruction
	{
		void Exec();
	}

	class WhileInstruction : Instruction
	{
		private BrainfuckProgram program;
		private Instruction[] instructions;
		public this(BrainfuckProgram program, Instruction[] instructions)
		{
			this.program = program;
			this.instructions = instructions;
		}
		public ~this()
		{
			delete this.instructions;
		}
		public void Exec()
		{
			while (program.buffer[program.pointerPosition] != 0)
			{
				for (var i = 0; i < this.instructions.Count; i++)
				{
					this.instructions[i].Exec();
				}
			}
		}
	}

	class IncrementInstruction : Instruction
	{
		private BrainfuckProgram program;
		public this(BrainfuckProgram program)
		{
			this.program = program;
		}

		public void Exec()
		{
			this.program.buffer[this.program.pointerPosition]++;
		}
	}
	class DecrementInstruction : Instruction
	{
		private BrainfuckProgram program;
		public this(BrainfuckProgram program)
		{
			this.program = program;
		}

		public void Exec()
		{
			this.program.buffer[this.program.pointerPosition]--;
		}
	}

	class IncrementPointerInstruction : Instruction
	{
		private BrainfuckProgram program;
		public this(BrainfuckProgram program)
		{
			this.program = program;
		}

		public void Exec()
		{
			this.program.pointerPosition++;
			if (this.program.buffer.Count <= this.program.pointerPosition)
			{
				this.program.pointerPosition = this.program.pointerPosition % this.program.buffer.Count;
			}
		}
	}

	class DecrementPointerInstruction : Instruction
	{
		private BrainfuckProgram program;
		public this(BrainfuckProgram program)
		{
			this.program = program;
		}

		public void Exec()
		{
			this.program.pointerPosition--;
			let bufferSize = this.program.buffer.Count;
			while (this.program.pointerPosition < 0)
			{
				this.program.pointerPosition = (bufferSize + this.program.pointerPosition);
			}
			if (bufferSize <= this.program.pointerPosition)
			{
				this.program.pointerPosition = this.program.pointerPosition % bufferSize;
			}
		}
	}

	class PrintInstruction : Instruction
	{
		private BrainfuckProgram program;
		public this(BrainfuckProgram program)
		{
			this.program = program;
		}

		public void Exec()
		{
			Console.Write(this.program.buffer[this.program.pointerPosition]);
		}
	}

	class InputInstruction : Instruction
	{
		private BrainfuckProgram program;
		public this(BrainfuckProgram program)
		{
			this.program = program;
		}

		public void Exec()
		{
			this.program.buffer[this.program.pointerPosition] = Console.In.Read();
		}
	}
}
