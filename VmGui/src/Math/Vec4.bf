using System;

namespace VmGui.Math
{
	[Ordered]
	public struct Vec4
	{
		public float x;
		public float y;
		public float z;
		public float w;

		//Color presets since Vec4 is often used as an RGBA color
		public static readonly Vec4 ColorRed = .(1.0f, 0.0f, 0.0f, 1.0f);
		public static readonly Vec4 ColorGreen = .(0.0f, 1.0f, 0.0f, 1.0f);
		public static readonly Vec4 ColorBlue = .(0.0f, 0.0f, 1.0f, 1.0f);
		public static readonly Vec4 ColorBlack = .(0.0f, 0.0f, 0.0f, 1.0f);
		public static readonly Vec4 ColorWhite = .(1.0f, 1.0f, 1.0f, 1.0f);

		public this()
		{
			this = default;
		}

		public this(float x, float y, float z, float w)
		{
			this.x = x;
			this.y = y;
			this.z = z;
			this.w = w;
		}

		public float Length
		{
			get
			{
				return Math.Sqrt(x*x + y*y + z*z + w*w);
			}
		}

		public float Distance(Vec4 b)
		{
			return Math.Sqrt(Math.Pow(b.x - this.x, 2.0f) + Math.Pow(b.y - this.y, 2.0f) + Math.Pow(b.z - this.z, 2.0f) + Math.Pow(b.w - this.w, 2.0f));
		}

		public Vec4 Normalize()
		{
			return this / Length;
		}

		public static Vec4 operator*(Vec4 a, float scalar)
		{
			return .(a.x * scalar, a.y * scalar, a.z * scalar, a.w * scalar);
		}

		public static Vec4 operator/(Vec4 a, float scalar)
		{
			return .(a.x / scalar, a.y / scalar, a.z / scalar, a.w / scalar);
		}

		public void operator+=(Vec4 rhs) mut
		{
			x += rhs.x;
			y += rhs.y;
			z += rhs.z;
			w += rhs.w;
		}

		public void operator-=(Vec4 rhs) mut
		{
			x -= rhs.x;
			y -= rhs.y;
			z -= rhs.z;
			w -= rhs.w;
		}

		public void operator*=(Vec4 rhs) mut
		{
			x *= rhs.x;
			y *= rhs.y;
			z *= rhs.z;
			w *= rhs.w;
		}

		public void operator/=(Vec4 rhs) mut
		{
			x /= rhs.x;
			y /= rhs.y;
			z /= rhs.z;
			w /= rhs.w;
		}

		public static Vec4 operator+(Vec4 lhs, Vec4 rhs)
		{
			return .(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w);
		}

		public static Vec4 operator-(Vec4 lhs, Vec4 rhs)
		{
			return .(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w);
		}

		public static Vec4 operator*(Vec4 lhs, Vec4 rhs)
		{
			return .(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z, lhs.w * rhs.w);
		}

		public override void ToString(String strBuffer)
		{
			strBuffer.AppendF("[{}, {}, {}, {}]", x, y, z, w);
		}
	}
}
