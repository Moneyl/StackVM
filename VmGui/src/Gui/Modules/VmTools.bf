using VmScriptingFun;
using VmGui.Math;
using VmGui.Gui;
using System.IO;
using System;
using ImGui;

namespace VmGui.Gui.Modules
{
	public class VmTools : IGuiModule
	{
		VM _vm = new VM() ~delete _;
		String _sourceString = new String() ~delete _;

		public this()
		{
			File.ReadAllText(scope $"{VmGui.BuildConfig.AssetsBasePath}/Test0.script", _sourceString);
			_vm.Parse(_sourceString);
		}

		void IGuiModule.Update(Application app)
		{
			DrawVariablesGui(app);
			DrawStackGui(app);
			DrawDisassemblerGui(app);
			DrawScriptGui(app);
			HandleInput(app);
		}

		private void DrawVariablesGui(Application app)
		{
			if(!ImGui.Begin(scope String()..Append(Icons.ICON_FA_SUBSCRIPT)..Append(" Variables").Ptr))
			{
				ImGui.End();
				return;
			}

			FontManager.FontL.Push();
			ImGui.Text("Variables");
			FontManager.FontL.Pop();
			ImGui.Separator();

			var globals = _vm.[Friend]_globals;
			if(ImGui.BeginTable("GlobalVariablesTable", 3, .ScrollY | .RowBg | .BordersOuter | .BordersV | .Resizable | .Reorderable | .Hideable))
			{
				ImGui.TableSetupScrollFreeze(1, 0); //Make first column always visible
				ImGui.TableSetupColumn("Name", .None);
				ImGui.TableSetupColumn("Type", .None);
				ImGui.TableSetupColumn("Value", .None);
				ImGui.TableHeadersRow();

				ImGui.ListClipper clipper = .();
				clipper.Begin((int32)globals.Count);
				while(clipper.Step())
				{
					for(int32 row = clipper.DisplayStart; row < clipper.DisplayEnd; row++)
					{
						ImGui.TableNextRow();

						var global = globals.[Friend]mEntries[row];
						var value = global.mValue;
						ImGui.TableSetColumnIndex(0);
						ImGui.Text(global.mKey.Ptr);

						ImGui.TableSetColumnIndex(1);
						ImGui.Text(value.ValueType().ToString(.. scope String()));

						ImGui.TableSetColumnIndex(2);
						if(value.IsNull())
							ImGui.Text("Null");
						else if(value.IsBool())
							ImGui.Text($"{value.AsBool()}");
						else if(value.IsNumber())
							ImGui.Text($"{value.AsNumber():G3}");
						else if(value.IsString())
							ImGui.Text($"\"{value.AsString()}\"");
						else if(value.IsObj())
							ImGui.Text($"{value.AsObj().Ptr}");
					}
				}

				ImGui.EndTable();
			}

			ImGui.End();
		}

		private void DrawStackGui(Application app)
		{
			if(!ImGui.Begin(scope String()..Append(Icons.ICON_FA_TH_LIST)..Append(" Stack").Ptr))
			{
				ImGui.End();
				return;
			}

			FontManager.FontL.Push();
			ImGui.Text("Stack");
			FontManager.FontL.Pop();
			ImGui.Separator();

			var vmStack = _vm.[Friend]_stack;
			int32 stackPos = (int32)_vm.[Friend]_stackPos;
			int32 stackTop = stackPos == 0 ? 0 : stackPos - 1;
			if(ImGui.BeginTable("StackDataTable", 3, .ScrollY | .RowBg | .BordersOuter | .BordersV | .Resizable | .Reorderable | .Hideable))
			{
				ImGui.TableSetupScrollFreeze(1, 0); //Make first column always visible
				ImGui.TableSetupColumn("Index", .None);
				ImGui.TableSetupColumn("Type", .None);
				ImGui.TableSetupColumn("Value", .None);
				ImGui.TableHeadersRow();

				//Todo: Use ListClipper here. Would be more performant when the stack has 100s of values
				for(int32 row = stackTop; row >= 0; row--)
				{
					ImGui.TableNextRow();

					var value = vmStack[row];
					ImGui.TableSetColumnIndex(0);
					ImGui.Text($"{row}");

					ImGui.TableSetColumnIndex(1);
					ImGui.Text(value.ValueType().ToString(.. scope String()));

					ImGui.TableSetColumnIndex(2);
					if(value.IsNull())
						ImGui.Text("Null");
					else if(value.IsBool())
						ImGui.Text($"{value.AsBool()}");
					else if(value.IsNumber())
						ImGui.Text($"{value.AsNumber():G3}");
					else if(value.IsString())
						ImGui.Text($"\"{value.AsString()}\"");
					else if(value.IsObj())
						ImGui.Text($"{value.AsObj().Ptr}");
				}

				ImGui.EndTable();
			}

			ImGui.End();
		}

		private void DrawDisassemblerGui(Application app)
		{
			if(!ImGui.Begin(scope String()..Append(Icons.ICON_FA_CODE)..Append(" Disassembler")))
			{
				ImGui.End();
				return;
			}

			FontManager.FontL.Push();
			ImGui.Text("Disassembler");
			FontManager.FontL.Pop();
			ImGui.Separator();

			ImGui.Indent(15.0f);
			if(ImGui.BeginTable("DisassemblerDataTable", 3, .ScrollY | .RowBg | .BordersOuter | .BordersV | .Resizable | .Reorderable | .Hideable))
			{
				ImGui.TableSetupScrollFreeze(1, 0); //Make first column always visible
				ImGui.TableSetupColumn("Bytecode", .None);
				ImGui.TableSetupColumn("Data", .None);
				ImGui.TableSetupColumn("Line", .None);
				ImGui.TableHeadersRow();

				//Todo: Use ListClipper here. Would be more performant when the stack has 100s of values
				var binary = _vm.[Friend]_binary;
				var bytecodes = binary.Bytecodes;
				var constants = binary.Constants;
				var lines = binary.Lines;
				uint32 binaryPos = _vm.[Friend]_binaryPos;
				ImGui.Vec2 currentBytecodePos = .();
				for(uint32 i = 0; i < bytecodes.Count; i++)
				{
					ImGui.TableNextRow();
					ImGui.TableSetColumnIndex(0);

					Bytecode bytecode = bytecodes[i];
					uint32 line = lines[i];
					uint32 data = 0; //Inline data that follows some bytecodes
					bool hasInlineData = bytecode == .Value || bytecode == .DefineGlobal || bytecode == .GetGlobal || bytecode == .SetGlobal;
					if(i == binaryPos)
					{
						currentBytecodePos = ImGui.GetCursorScreenPos();
					}
					if(hasInlineData && i < bytecodes.Count - 1)
					{
						data = *(uint32*)&bytecodes[i + 1];
						i += 4;
					}

					ImGui.Text(bytecode.ToString(.. scope String()));

					ImGui.TableSetColumnIndex(1);
					if(hasInlineData)
						ImGui.Text(constants[data].ToString(.. scope String())); //Get inline value from constants table if applicable
					else
						ImGui.Text("N/A"); //Else N/A

					ImGui.TableSetColumnIndex(2);
					ImGui.Text($"{line}");
				}

				//Todo: Replace with triangle
				var cursorPos = ImGui.GetCursorPos();
				var circlePos = currentBytecodePos;
				circlePos.x -= 15.0f;
				circlePos.y += ImGui.GetFontSize() / 2.0f;
				ImGui.GetForegroundDrawList().AddCircleFilled(circlePos, 7.0f, ImGui.ColorConvertFloat4ToU32(.(1.0f, 1.0f, 0.0f, 1.0f)));
				ImGui.SetCursorPos(cursorPos);

				ImGui.EndTable();
			}

			ImGui.End();
		}

		private void DrawScriptGui(Application app)
		{
			if(!ImGui.Begin(scope String()..Append(Icons.ICON_FA_CODE)..Append(" Script").Ptr))
			{
				ImGui.End();
				return;
			}

			DrawToolbar(app);
			ImGui.Separator();
			
			//TODO: Support comments here. Tokenizer currently discards them.
			//TODO: Color text by using token stringview ptrs to source string
			//Draw script colored by token
			ImGui.PushStyleVar(.FrameBorderSize, 0.0f);
			ImGui.PushStyleColor(.ChildBg, ImGui.GetStyle().Colors[(int)ImGui.Col.FrameBg]);
			ImGui.BeginChild("##Script");

			ImGui.Indent(25.0f);
			Gui.Util.TextMultiline("##SourceStringEditor", _sourceString, .(-1.0f, 400.0f));
			//ImGui.TextWrapped(_sourceString.Ptr);

			ImGui.EndChild();
			ImGui.PopStyleColor();
			ImGui.PopStyleVar();
			ImGui.End();
		}

		//Reset vm state and run source script
		private void Run()
		{
			_vm.Reset();
			_vm.Parse(_sourceString);
			_vm.Interpret();
		}

		//Reset vm state but don't interpret any bytecode yet
		private void Reset()
		{
			_vm.Reset();
			_vm.Parse(_sourceString);
		}	

		private void DrawToolbar(Application app)
		{
			ImGui.Vec4 green = .(0.556f, 0.823f, 0.541f, 1.0f);
			ImGui.Vec4 red = .(0.82f, 0.271f, 0.271f, 1.0f);
			ImGui.PushStyleVar(.FrameBorderSize, 0.0f);
			ImGui.PushStyleColor(.Button, .());
			ImGui.PushStyleColor(.ButtonActive, .());
			ImGui.PushStyleColor(.Text, green);

			if (ImGui.Button(Icons.ICON_FA_PLAY))
			{
				Run();
			}
			Gui.Util.TooltipOnPrevious("Run script (F5)");

			ImGui.SameLine();
			if (ImGui.Button(Icons.ICON_FA_STEP_FORWARD))
			{
				_vm.Step();
			}
			Gui.Util.TooltipOnPrevious("Step one instruction (F6)");

			ImGui.SameLine();
			ImGui.PushStyleColor(.Text, red);
			if (ImGui.Button(Icons.ICON_FA_STOP))
			{
				Reset();
			}
			Gui.Util.TooltipOnPrevious("Reset VM (F7)");

			ImGui.PopStyleColor(4);
			ImGui.PopStyleVar();
		}

		private void HandleInput(Application app)
		{
			if(app.Input.KeyPressed(.F5))
				Run();
			else if(app.Input.KeyPressed(.F6))
				_vm.Step();
			else if(app.Input.KeyPressed(.F7))
				Reset();
		}
	}
}
