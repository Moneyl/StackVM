using System.Collections;
using System;
using glfw_beef;

namespace VmGui.Util
{
	//Wrapper for glfw input system. Provides event interface so class interfaces can react to input events
	public class Input
	{
		//Window reference
		private Window _window;
		//Delegates used for input callbacks
		private delegate void(GlfwWindow* window, GlfwInput.Key key, int scancode, GlfwInput.Action action, int mods) _keyCallbackDelegate = new => KeyCallback;
		private delegate void(GlfwWindow* window, double x, double y) _mouseMoveCallbackDelegate = new => MouseMoveCallback;
		private delegate void(GlfwWindow* window, GlfwInput.MouseButton button, GlfwInput.Action action, int mods) _mouseButtonCallbackDelegate = new => MouseButtonCallback;
		//Event for input callbacks
		public Event<delegate void(Input state)> InputEvent = default;

		//Input state
		private List<bool> _keyDownStates = new List<bool>(349);
		private List<bool> _mouseDownStates = new List<bool>(8);
		private bool _shiftDown = false;
		private bool _controlDown = false;
		private bool _altDown = false;
		private bool _capsLockDown = false;
		private bool _numLockDown = false;
		private bool _superDown = false;
		private float _lastMouseX = 0.0f;
		private float _lastMouseY = 0.0f;
		private float _mousePosX = 0.0f;
		private float _mousePosY = 0.0f;
		private float _mouseDeltaX = 0.0f;
		private float _mouseDeltaY = 0.0f;
		private bool _keyPressed = false;
		private bool _mouseButtonPressed = false;
		private bool _mouseMoved = false;

		public this(Window window)
		{
			_window = window;

			//Set mouse and keyboard button states to false
			for(uint32 i = 0; i < 349; i++)
				_keyDownStates.Add(false);
			for(uint32 i = 0; i < 8; i++)
				_mouseDownStates.Add(false);

			//Set input callbacks
			Glfw.SetKeyCallback(_window.Base, _keyCallbackDelegate);
			Glfw.SetCursorPosCallback(_window.Base, _mouseMoveCallbackDelegate);
			Glfw.SetMouseButtonCallback(_window.Base, _mouseButtonCallbackDelegate);
		}

		public ~this()
		{
			delete _keyDownStates;
			delete _mouseDownStates;
			InputEvent.Dispose();
		}

		//Remove all input callbacks
		public void Reset()
		{
			InputEvent = default;
		}

		//Triggers input callbacks
		public void Update()
		{
			_keyPressed = false;
			_mouseButtonPressed = false;
			_mouseMoved = false;
			InputEvent.Invoke(this);
		}

		//Glfw key input callback
		private void KeyCallback(GlfwWindow* window, GlfwInput.Key key, int scancode, GlfwInput.Action action, int mods)
		{
			if((int)key >= _keyDownStates.Count || key == .Unknown)
				return;

			if(action == GlfwInput.Action.Press)
			{
				_keyDownStates[(int)key] = true;
				_keyPressed = true;
			}
			if(action == GlfwInput.Action.Release)
			{
				_keyDownStates[(int)key] = false;
			}

			_shiftDown = (mods == (int)GlfwInput.Modifiers.Shift);
			_controlDown = (mods == (int)GlfwInput.Modifiers.Control);
			_altDown = (mods == (int)GlfwInput.Modifiers.Alt);
			_capsLockDown = (mods == (int)GlfwInput.Modifiers.CapsLock);
			_numLockDown = (mods == (int)GlfwInput.Modifiers.NumLock);
			_superDown = (mods == (int)GlfwInput.Modifiers.Super);
		}

		//Glfw mouse move callback
		private void MouseMoveCallback(GlfwWindow* window, double x, double y)
		{
			_mousePosX = (float)x;
			_mousePosY = (float)y;
			_mouseDeltaX = _mousePosX - _lastMouseX;
			_mouseDeltaY = _mousePosY - _lastMouseY;
			_lastMouseX = _mousePosX;
			_lastMouseY = _mousePosY;

			//If mouse moved, set _mouseMoved to true for this frame
			if(!Math.Util.Equal(x, 0.0, 1e-3) || !Math.Util.Equal(y, 0.0, 1e-3))
				_mouseMoved = true;
		}

		//Glfw mouse press callback
		private void MouseButtonCallback(GlfwWindow* window, GlfwInput.MouseButton button, GlfwInput.Action action, int mods)
		{
			if(action == GlfwInput.Action.Press)
			{
				_mouseDownStates[(int)button] = true;
				_mouseButtonPressed = true;
			}
			if(action == GlfwInput.Action.Release)
			{
				_mouseDownStates[(int)button] = false;
			}
		}

		//Returns true if the provided is down
		public bool KeyDown(GlfwInput.Key keyCode) { return _keyDownStates[(int)keyCode]; }
		//Returns true if the provided mouse button is down
		public bool MouseButtonDown(GlfwInput.MouseButton keyCode) { return _mouseDownStates[(int)keyCode]; }

		public bool ShiftDown() { return _shiftDown; }
		public bool ControlDown() { return _controlDown; }
		public bool AltDown() { return _altDown; }
		public bool CapsLockDown() { return _capsLockDown; }
		public bool NumLockDown() { return _numLockDown; }
		public bool SuperDown() { return _superDown; }

		public float MousePosX() { return _mousePosX; }
		public float MousePosY() { return _mousePosY; }
		public float MouseDeltaX() { return _mouseDeltaX; }
		public float MouseDeltaY() { return _mouseDeltaY; }

		//Returns true if the mouse moved this frame
		public bool MouseMoved() { return _mouseMoved; }
		//Returns true if the provided key was pressed this frame
		public bool KeyPressed(GlfwInput.Key keyCode) { return _keyPressed && KeyDown(keyCode); }
		//Returns true if any mouse button was pressed this frame
		public bool MouseButtonPressed() { return _mouseButtonPressed; }
	}
}