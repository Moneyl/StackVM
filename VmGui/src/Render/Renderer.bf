using VmGui.Util;
using VmGui.Math;

namespace VmGui.Render
{
	public class Renderer
	{
		Window _window;
		ImGuiRenderer _imGuiRenderer ~delete _;
		public Vec4 ClearColor = .(0.0f, 0.0f, 0.0f, 1.0f);

		public this(Window window)
		{
			_window = window;
			_imGuiRenderer = new ImGuiRenderer(_window);
		}

		public void BeginFrame()
		{
			_imGuiRenderer.BeginFrame();
		}

		public void EndFrame(f32 deltaTime)
		{
			_window.ClearColor(ClearColor.x, ClearColor.y, ClearColor.z, ClearColor.w);
			_imGuiRenderer.EndFrame();
			_window.SwapBuffers();
		}

		public void OnResize(uint32 width, uint32 height)
		{
			GL.glViewport(0, 0, width, height);
		}
	}
}
