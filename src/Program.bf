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
			var fileContent = new String();
			switch (File.ReadAllText(arg[0], fileContent))
			{
			case .Err(let err):
				Console.WriteLine("Error reading file: {}", err);
				delete fileContent;
				return;
			default:
				break;
			}

			let prog = new BrainfuckProgram(bufferSize);
			if (prog.ParseProgram(fileContent) case .Err(let err))
			{
				Console.WriteLine("Error while parsing program: {}\nAborting...", err);
				delete fileContent;
				delete prog;
				return;
			}
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
		public this(int bufferSize)
		{
			this.buffer = new char8[bufferSize];
		}

		public ~this()
		{
			if (this.instructions != null)
			{
				for (var i = 0; i < this.instructions.Count; i++)
				{
					delete ((Object)this.instructions[i]);
				}
			}
		}

		public Result<void, String> ParseProgram(String program)
		{
			let instructionsList = new List<List<Instruction>>();
			instructionsList.Add(new List<Instruction>());
			char8 lastInstruction = '\0';
			int lastInstructionCount = 0;
			void setLastInstruction(char8 instruction)
			{
				lastInstruction = instruction;
				lastInstructionCount = 1;
			}
			for (var i = 0; i < program.Length; i++)
			{
				if (!isBrainfuckValid(program[i]))
				{
					continue;
				}
				if (lastInstruction != program[i] && isStackableInstruction(lastInstruction))
				{
					switch (lastInstruction)
					{
					case '>':
						instructionsList[instructionsList.Count - 1].Add(new IncrementPointerInstruction(this, lastInstructionCount));
						break;
					case '<':
						instructionsList[instructionsList.Count - 1].Add(new DecrementPointerInstruction(this, lastInstructionCount));
						break;
					case '+':
						instructionsList[instructionsList.Count - 1].Add(new IncrementInstruction(this, lastInstructionCount));
						break;
					case '-':
						instructionsList[instructionsList.Count - 1].Add(new DecrementInstruction(this, lastInstructionCount));
						break;
					}
					lastInstructionCount = 0;
					lastInstruction = '\0';
				} else if (lastInstruction == program[i])
				{
					lastInstructionCount++;
					continue;
				}
				switch (program[i])
				{
				case '>':
					setLastInstruction(program[i]);
					break;
				case '<':
					setLastInstruction(program[i]);
					break;
				case '+':
					setLastInstruction(program[i]);
					break;
				case '-':
					setLastInstruction(program[i]);
					break;
				case '[':
					instructionsList.Add(new List<Instruction>());
					break;
				case ']':
					let whileInstructions = instructionsList.PopBack();
					if (whileInstructions.Count > 0)
					{
						let instructionsArray = new Instruction[whileInstructions.Count];
						whileInstructions.CopyTo(instructionsArray);
						let whileInstruction = new WhileInstruction(this, instructionsArray);
						instructionsList[instructionsList.Count - 1].Add(whileInstruction);
					}
					delete whileInstructions;
					break;
				case '.':
					instructionsList[instructionsList.Count - 1].Add(new PrintInstruction(this));
					break;
				case ',':
					instructionsList[instructionsList.Count - 1].Add(new InputInstruction(this));
					break;
				}
			}
			switch (lastInstruction)
			{
			case '>':
				instructionsList[instructionsList.Count - 1].Add(new IncrementPointerInstruction(this, lastInstructionCount));
				break;
			case '<':
				instructionsList[instructionsList.Count - 1].Add(new DecrementPointerInstruction(this, lastInstructionCount));
				break;
			case '+':
				instructionsList[instructionsList.Count - 1].Add(new IncrementInstruction(this, lastInstructionCount));
				break;
			case '-':
				instructionsList[instructionsList.Count - 1].Add(new DecrementInstruction(this, lastInstructionCount));
				break;
			}
			let instructions = instructionsList.PopBack();
			if (instructionsList.Count > 0)
			{
				while (instructionsList.Count > 0)
				{
					let list = instructionsList.PopBack();
					for (var i = 0; i < list.Count; i++)
					{
						delete ((Object)list[i]);
					}
					delete list;
				}
				delete instructionsList;
				for (var i = 0; i < instructions.Count; i++)
				{
					delete ((Object)instructions[i]);
				}
				delete instructions;
				return .Err("Loop not closed");
			}
			let instructionsArray = new Instruction[instructions.Count];
			instructions.CopyTo(instructionsArray);
			this.instructions = instructionsArray;
			delete instructions;
			delete instructionsList;
			return .Ok;

			bool isStackableInstruction(char8 chr)
			{
				return chr == '>' || chr == '<' || chr == '+' || chr == '-';
			}
			bool isBrainfuckValid(char8 chr)
			{
				return chr == '>' || chr == '<' || chr == '+' || chr == '-' || chr == '[' || chr == ']' || chr == '.' || chr == ',';
			}
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
			for (var i = 0; i < this.instructions.Count; i++)
			{
				delete ((Object)this.instructions[i]);
			}
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
		private int incrementCount;
		public this(BrainfuckProgram program, int incrementCount)
		{
			this.program = program;
			this.incrementCount = incrementCount;
		}

		public void Exec()
		{
			this.program.buffer[this.program.pointerPosition] += incrementCount;
		}
	}
	class DecrementInstruction : Instruction
	{
		private BrainfuckProgram program;
		private int decrementCount;
		public this(BrainfuckProgram program, int decrementCount)
		{
			this.program = program;
			this.decrementCount = decrementCount;
		}

		public void Exec()
		{
			this.program.buffer[this.program.pointerPosition] -= decrementCount;
		}
	}

	class IncrementPointerInstruction : Instruction
	{
		private BrainfuckProgram program;
		private int incrementCount;
		public this(BrainfuckProgram program, int incrementCount)
		{
			this.program = program;
			this.incrementCount = incrementCount;
		}

		public void Exec()
		{
			this.program.pointerPosition += this.incrementCount;
			if (this.program.buffer.Count <= this.program.pointerPosition)
			{
				this.program.pointerPosition = this.program.pointerPosition % this.program.buffer.Count;
			}
		}
	}

	class DecrementPointerInstruction : Instruction
	{
		private BrainfuckProgram program;
		private int decrementCount;
		public this(BrainfuckProgram program, int decrementCount)
		{
			this.program = program;
			this.decrementCount = decrementCount;
		}

		public void Exec()
		{
			this.program.pointerPosition -= this.decrementCount;
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
