using System;
using VmGui.Gui;
using VmGui.Math;
using ImGui;

namespace VmGui.Gui.Modules
{
	//Main menu bar and dockspace that all other modules attach to
	public class GuiBase : IGuiModule
	{
		private ImGui.DockNodeFlags dockspaceFlags = 0;

		void IGuiModule.Update(Application app)
		{
			DrawMainMenuBar(app);
			DrawDockspace(app);
#if DEBUG
			ImGui.ShowDemoWindow();
#endif
		}

		private void DrawMainMenuBar(Application app)
		{
			if (ImGui.BeginMainMenuBar())
			{
				if(ImGui.BeginMenu("File"))
				{
					if(ImGui.MenuItem("Open file...")) { }
					if(ImGui.MenuItem("Save file...")) { }
					if(ImGui.MenuItem("Exit")) { }
					ImGui.EndMenu();
				}
				if(ImGui.BeginMenu("Edit"))
				{
					ImGui.EndMenu();
				}
				if(ImGui.BeginMenu("View"))
				{
					//Todo: Put toggles for other guis in this layer here
					ImGui.EndMenu();
				}
				if(ImGui.BeginMenu("Help"))
				{
					if(ImGui.MenuItem("Welcome")) { }
					if(ImGui.MenuItem("Metrics")) { }
					if(ImGui.MenuItem("About")) { }
					ImGui.EndMenu();
				}

				var drawList = ImGui.GetWindowDrawList();
				String framerate = scope String()..AppendF("{0:G4}", app.DeltaTime * 1000.0f);
				StringView labelAndSeparator = "|    Frametime(ms): ";
				drawList.AddText(.(ImGui.GetCursorPosX(), 5.0f), 0xF2F5FAFF, "|    Frametime(ms): ");
				var textSize = ImGui.CalcTextSize("|    Frametime(ms): ");
				drawList.AddText(.(ImGui.GetCursorPosX() + (f32)textSize.x, 5.0f), ImGui.ColorConvertFloat4ToU32(Gui.Util.SecondaryTextColor), framerate.CStr());

				ImGui.EndMainMenuBar();
			}
		}

		private void DrawDockspace(Application app)
		{
			//Dockspace flags
			dockspaceFlags = ImGui.DockNodeFlags.None | ImGui.DockNodeFlags.PassthruCentralNode;

			//Parent window flags
			ImGui.WindowFlags windowFlags = ImGui.WindowFlags.NoDocking | ImGui.WindowFlags.NoTitleBar | ImGui.WindowFlags.NoCollapse
			    | ImGui.WindowFlags.NoResize | ImGui.WindowFlags.NoMove
			    | ImGui.WindowFlags.NoBringToFrontOnFocus | ImGui.WindowFlags.NoNavFocus | ImGui.WindowFlags.NoBackground;

			//Set dockspace size and params
			var viewport = ImGui.GetMainViewport();
			ImGui.SetNextWindowPos(viewport.GetWorkPos());
			var dockspaceSize = viewport.GetWorkSize();
			ImGui.SetNextWindowSize(dockspaceSize);
			ImGui.SetNextWindowViewport(viewport.ID);
			ImGui.PushStyleVar(ImGui.StyleVar.WindowRounding, 0.0f);
			ImGui.PushStyleVar(ImGui.StyleVar.WindowBorderSize, 0.0f);
			ImGui.PushStyleVar(ImGui.StyleVar.WindowPadding, .(0.0f, 0.0f));
			ImGui.Begin("Dockspace parent window", null, windowFlags);
			ImGui.PopStyleVar(3);

			//Create dockspace
			var io = ImGui.GetIO();
			if ((io.ConfigFlags & ImGui.ConfigFlags.DockingEnable) != 0)
			{
			    ImGui.ID dockspaceId = ImGui.GetID("Editor dockspace");
			    ImGui.DockSpace(dockspaceId, .(0.0f, 0.0f), dockspaceFlags);
			}

			ImGui.End();
		}
	}
}
