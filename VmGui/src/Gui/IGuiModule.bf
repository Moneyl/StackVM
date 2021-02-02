

namespace VmGui.Gui
{
	//All GUIs must implement this interface
	public interface IGuiModule
	{
		//Per-frame update
		public void Update(Application app);
	}
}
