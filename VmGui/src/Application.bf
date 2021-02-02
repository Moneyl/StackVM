using System.Diagnostics;
using VmGui.Gui.Modules;
using VmGui.Render;
using VmGui.Util;
using VmGui.Gui;
using System;

namespace VmGui
{
	public class Application
	{
		//Core classes
		private Window _window ~delete _;
		public Input Input ~delete _;
		private Renderer _renderer ~delete _;
		private Gui _gui ~delete _;

		private bool _shouldExit = false;
		private delegate void(uint32 width, uint32 height) _onResizeDelegate = new => OnResize;
		private delegate void(Input state) _inputEventDelegate = new => InputEvent;

		//Frame timing variables
		private float _deltaTime = 1.0f / 60.0f;
		private uint32 _maxFrameRate = 60;
		private float _maxFrameRateDelta = 1.0f / (float)_maxFrameRate;
		private Stopwatch _frameTimer = new Stopwatch(false) ~delete _;
		public float DeltaTime => _deltaTime;

		public ~this()
		{
			delete _onResizeDelegate;
			delete _inputEventDelegate;
		}

		public void Run()
		{
			Init();
			MainLoop();
		}

		private void Init()
		{
			_window = new Window(1280, 720, "Vm Gui");
			Input = new Input(_window);
			_renderer = new Renderer(_window);
			_gui = new Gui();
			_gui.AddModule(new GuiBase());
			_gui.AddModule(new VmTools());
		}

		private void MainLoop()
		{
			_frameTimer.Start();
			while (!_window.ShouldClose() && !_shouldExit)
			{
				//Update
				Input.BeginFrame();
				_window.Poll();
				Input.Update();
				_renderer.BeginFrame();
				_gui.Update(this);
				_renderer.EndFrame(_deltaTime);

				//Wait for target framerate
				while(((float)_frameTimer.ElapsedMicroseconds / 1000000.0f) < _maxFrameRateDelta){ }
				_deltaTime = (float)_frameTimer.ElapsedMicroseconds / 1000000.0f;
				_frameTimer.Restart();
			}
		}

		private void OnResize(uint32 width, uint32 height)
		{
			_renderer.OnResize(width, height);
		}

		private void InputEvent(Input state)
		{
			//Update misc state
			_shouldExit = Input.KeyDown(.Escape);
		}
	}
}
