using VmGui.Gui;
using VmGui.Math;
using System;
using ImGui;

namespace VmGui.Gui
{
	public static class Util
	{
		public static ImGui.Vec4 SecondaryTextColor = .(0.2f, 0.7f, 1.0f, 1.00f); //Light blue;
		public static ImGui.Vec4 TertiaryTextColor = .(0.64f, 0.67f, 0.69f, 1.00f); //Light grey;
		public static ImGui.Vec4 Red = .(0.784f, 0.094f, 0.035f, 1.0f);

		//Draw label and value next to each other with value using secondary color
		public static void LabelAndValue(StringView label, StringView value, ImGui.Vec4 color = SecondaryTextColor)
		{
			ImGui.Text(label.Ptr);
			ImGui.SameLine();
			ImGui.SetCursorPosX(ImGui.GetCursorPosX() - 4.0f);
			ImGui.TextColored(color, value.Ptr);
		}

		//Add mouse-over tooltip to previous ui element. Returns true if the target is being hovered
		public static bool TooltipOnPrevious(StringView description, ImGui.Font* Font = null)
		{
			var font = Font;
			if(font == null)
				font = FontManager.FontDefault.Font;

			bool hovered = ImGui.IsItemHovered();
		    if (hovered)
		    {
		        ImGui.PushFont(Font);
		        ImGui.BeginTooltip();
		        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 35.0f);
		        ImGui.TextUnformatted(description.Ptr);
		        ImGui.PopTextWrapPos();
		        ImGui.EndTooltip();
		        ImGui.PopFont();
		    }
			return hovered;
		}
	}
}
