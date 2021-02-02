using System.Collections;

namespace VmGui.Gui
{
	class Gui
	{
		private List<IGuiModule> _modules = new List<IGuiModule>() ~DeleteContainerAndItems!(_modules);

		//Update all modules that are part of this layer.
		public void Update(Application app)
		{
			for(var module in _modules)
				module.Update(app);
		}

		public void AddModule(IGuiModule module)
		{
			_modules.Add(module);
		}
	}
}
