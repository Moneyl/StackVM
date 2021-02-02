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

		private struct InputTextCallback_UserData
		{
			public String Str;
			public ImGui.InputTextCallback ChainCallback;
			public void* ChainCallbackUserData;

			public this(String str, ImGui.InputTextCallback chainCallback, void* chainCallbackUserData)
			{
				Str = str;
				ChainCallback = chainCallback;
				ChainCallbackUserData = chainCallbackUserData;
			}
		}

		private static int InputTextCallback(ImGui.InputTextCallbackData* data)
		{
			InputTextCallback_UserData* userData = (InputTextCallback_UserData*)data.UserData;
			if(data.EventFlag == .CallbackResize) //Resize buffer
			{
				String str = userData.Str;
				Runtime.Assert(data.Buf == str.Ptr);
				str.Ptr[str.Length + 1] = ' '; //Remove null terminator
				//Resize buffer and copy string to it
				str.[Friend]mLength = data.BufTextLen;
				str.Reserve(data.BufTextLen);
				Internal.MemCpy(str.Ptr, data.Buf, data.BufTextLen);
				data.Buf = str.Ptr;
			}
			else if(userData.ChainCallback != null)
			{
				data.UserData = userData.ChainCallbackUserData;
				return userData.ChainCallback(data);
			}
			return 0;
		}

		//Input text string and auto resize str buffer
		public static bool TextMultiline(char8* label, String str, ImGui.Vec2 size = .(0.0f, 0.0f), ImGui.InputTextFlags flags = .None, ImGui.InputTextCallback callback = null, void* userData = null)
		{
			var flagsTemp = flags;
			flagsTemp |= .CallbackResize;
			InputTextCallback_UserData cbUserData = .(str, callback, userData);
			return ImGui.InputTextMultiline(label, str, (u64)str.Length + 1, size, flagsTemp, => InputTextCallback, &cbUserData);
		}
	}
}
