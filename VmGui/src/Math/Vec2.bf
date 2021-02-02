using System;

namespace VmGui.Math
{
	[Ordered]
	public struct Vec2
	{
		public float x;
		public float y;

		public this()
		{
			this = default;
		}

		public this(float x, float y)
		{
			this.x = x;
			this.y = y;
		}

		public float Length
		{
			get
			{
				return Math.Sqrt(x*x + y*y);
			}
		}

		public float Distance(Vec2 b)
		{
			return Math.Sqrt(Math.Pow(b.x - this.x, 2.0f) + Math.Pow(b.y - this.y, 2.0f));
		}

		public Vec2 Normalize()
		{
			if(Length == 0.0f)
				return this;
			else
				return this / Length;
		}

		public static Vec2 operator*(Vec2 a, float scalar)
		{
			return .(a.x * scalar, a.y * scalar);
		}

		public static Vec2 operator/(Vec2 a, float scalar)
		{
			return .(a.x / scalar, a.y / scalar);
		}

		public void operator+=(Vec2 rhs) mut
		{
			x += rhs.x;
			y += rhs.y;
		}

		public void operator-=(Vec2 rhs) mut
		{
			x -= rhs.x;
			y -= rhs.y;
		}

		public void operator*=(Vec2 rhs) mut
		{
			x *= rhs.x;
			y *= rhs.y;
		}

		public void operator/=(Vec2 rhs) mut
		{
			x /= rhs.x;
			y /= rhs.y;
		}

		public static Vec2 operator+(Vec2 lhs, Vec2 rhs)
		{
			return .(lhs.x + rhs.x, lhs.y + rhs.y);
		}

		public static Vec2 operator-(Vec2 lhs, Vec2 rhs)
		{
			return .(lhs.x - rhs.x, lhs.y - rhs.y);
		}

		public override void ToString(String strBuffer)
		{
			strBuffer.AppendF("[{}, {}]", x, y);
		}
	}
}
