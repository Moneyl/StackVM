using System;

namespace VmGui
{
	public static class BuildConfig
	{
#if DEBUG
		public const String AssetsBasePath = "C:/Users/moneyl/source/repos/VmScriptingFun/assets/";
#else
		public const String AssetsBasePath = "./assets/";
#endif
	}
}
