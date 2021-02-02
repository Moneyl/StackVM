using System;

namespace VmGui.Math
{
	public static class Util
	{
		const double _epsilonDouble = 2.2204460492503131e-016;

		public static bool Equal(double a, double b, double maxDiff = _epsilonDouble)
		{
		    return Math.Abs(a - b) < maxDiff;
		}

		public static Vec2 Lerp(Vec2 currentVal, Vec2 targetVal, float interpolant)
		{
			return currentVal * (1.0f - interpolant) + targetVal * interpolant;
		}
	}
}
