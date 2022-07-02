using GLFW;
using System;
using System.Collections;
using VmGui.Math;

namespace VmGui.Util
{
	//Wrapper for GLFW window. The constructor creates a new window and initializes the OpenGL context
	public class Window
	{
		private uint32 _width;
		private uint32 _height;
		private GlfwWindow* _window;
		private delegate void(GlfwWindow* window, int width, int height) _framebufferResizeCallbackDelegate = new => FramebufferResizeCallback;

		public Event<delegate void(uint32 width, uint32 height)> ResizeEvent = default;
		public GlfwWindow* Base { get { return _window; } }
		public uint32 Width { get { return _width; } }
		public uint32 Height { get { return _height; } }
		public Vec2 Size { get { return .(_width, _height); } }

		public this(uint32 width, uint32 height, System.StringView title)
		{
			_width = width;
			_height = height;

			//Init GLFW and create window
			Glfw.Init();
			Glfw.WindowHint(GlfwWindow.Hint.ContextVersionMajor, 3);
			Glfw.WindowHint(GlfwWindow.Hint.ContextVersionMinor, 3);
			Glfw.WindowHint(GlfwWindow.Hint.OpenGlProfile, Glfw.OpenGlProfile.CoreProfile);
			_window = Glfw.CreateWindow(_width, _height, title, null, null);
			Glfw.MakeContextCurrent(_window);

			//Init OpenGL
			GL.Init(=> Glfw.GetProcAddress);

			//Set framebuffer resize callback
			Glfw.SetFramebufferSizeCallback(_window, _framebufferResizeCallbackDelegate);

			//Put window on second monitor in debug builds since this is convenient in my dev setup
#if DEBUG
			int count = 0;
			GlfwMonitor** monitors = Glfw.GetMonitors(ref count);
			int monitor2x = 0;
			int monitor2y = 0;
			Glfw.GetMonitorPos(monitors[1], ref monitor2x, ref monitor2y);
			Glfw.SetWindowPos(_window, monitor2x, monitor2y);
			Glfw.SetWindowSize(_window, _width, _height); //Must set size again after changing monitors. Otherwise size won't be correct which causes many bugs
			Glfw.MaximizeWindow(_window);
#else
			Glfw.SetWindowPos(_window, 40, 40);
#endif
		}

		public ~this()
		{
			Glfw.DestroyWindow(_window);
			Glfw.Terminate();
		}

		//Remove all ResizeEvent callbacks
		public void Reset()
		{
			ResizeEvent = default;
		}

		//Poll window for OS events
		public void Poll()
		{
			Glfw.PollEvents();
		}

		public void ClearColor(float red, float green, float blue, float alpha)
		{
			GL.glClearColor(red, green, blue, alpha);
			GL.glClear(GL.GL_COLOR_BUFFER_BIT);
		}

		public void SwapBuffers()
		{
			Glfw.SwapBuffers(_window);
		}

		public bool ShouldClose()
		{
			return Glfw.WindowShouldClose(_window);
		}

		private void FramebufferResizeCallback(GlfwWindow* window, int width, int height)
		{
			ResizeEvent.Invoke((uint32)width, (uint32)height);
		}
	}
}
