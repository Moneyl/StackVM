using ImGui;
using System;

namespace VmGui.Gui
{
	public static class FontManager
	{
		public static void RegisterFonts()
		{
			 
			ImGui.FontConfig iconConfig = .();
			iconConfig.MergeMode = true;
			iconConfig.PixelSnapH = true;

			FontSmall.Load(15.0f, &iconConfig, (uint16*)&_iconRanges);
			FontDefault.Load(17.0f, &iconConfig, (uint16*)&_iconRanges);
			FontL.Load(23.0f, &iconConfig, (uint16*)&_iconRanges);
			FontXL.Load(27.0f, &iconConfig, (uint16*)&_iconRanges);

			ImGui.GetIO().FontDefault = FontDefault.Font;
		}

		//Heap allocated to ensure it stays alive until dear imgui is done with it
		private static uint16[3] _iconRanges = .(Icons.ICON_MIN_FA, Icons.ICON_MAX_FA, 0);
		public static ImGuiFont FontSmall;
		public static ImGuiFont FontDefault;
		public static ImGuiFont FontL;
		public static ImGuiFont FontXL;

		//Font class used by FontManager
	  	public struct ImGuiFont
		{
			private float _size = 12.0f;
			private ImGui.Font* _font;

			public float Size { get { return _size; } }
			public ImGui.Font* Font { get { return _font; } }

			public void Push() { ImGui.PushFont(_font); }
			public void Pop() { ImGui.PopFont(); }
			public void Load(float size, ImGui.FontConfig* fontConfig, uint16* glyphRanges) mut
			{
				_size = size;
				var io = ImGui.GetIO();
				//Load font
				io.Fonts.AddFontFromFileTTF(BuildConfig.AssetsBasePath + "fonts/Ruda-Bold.ttf", _size);
				//Load FontAwesome image font
				_font = io.Fonts.AddFontFromFileTTF(BuildConfig.AssetsBasePath + "fonts/fa-solid-900.ttf", _size, fontConfig, glyphRanges);
			}
		}
	}
}
