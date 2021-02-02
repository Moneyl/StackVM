using System;

namespace VmGui.Math
{
	[Ordered]
	public struct Vec3
	{
		public float x;
		public float y;
		public float z;

		//Color presets since Vec3 is often used as an RGB color
		public static readonly Vec3 ColorRed = .(1.0f, 0.0f, 0.0f);
		public static readonly Vec3 ColorGreen = .(0.0f, 1.0f, 0.0f);
		public static readonly Vec3 ColorBlue = .(0.0f, 0.0f, 1.0f);
		public static readonly Vec3 ColorBlack = .(0.0f, 0.0f, 0.0f);
		public static readonly Vec3 ColorWhite = .(1.0f, 1.0f, 1.0f);

		public this()
		{
			this = default;
		}

		public this(float x, float y, float z)
		{
			this.x = x;
			this.y = y;
			this.z = z;
		}

		public float Length
		{
			get
			{
				return Math.Sqrt(x*x + y*y + z*z);
			}
		}

		public float Distance(Vec3 b)
		{
			return Math.Sqrt(Math.Pow(b.x - this.x, 2.0f) + Math.Pow(b.y - this.y, 2.0f) + Math.Pow(b.z - this.z, 2.0f));
		}

		public Vec3 Normalize()
		{
			return this / Length;
		}

		public Vec3 Cross(Vec3 b)
		{
			return .(
					 (y * b.z) - (z * b.y),
					 (z * b.x) - (x * b.z),
					 (x * b.y) - (y * b.x)
					);
		}

		public static Vec3 operator*(Vec3 a, float scalar)
		{
			return .(a.x * scalar, a.y * scalar, a.z * scalar);
		}

		public static Vec3 operator/(Vec3 a, float scalar)
		{
			return .(a.x / scalar, a.y / scalar, a.z / scalar);
		}

		public void operator+=(Vec3 rhs) mut
		{
			x += rhs.x;
			y += rhs.y;
			z += rhs.z;
		}

		public void operator-=(Vec3 rhs) mut
		{
			x -= rhs.x;
			y -= rhs.y;
			z -= rhs.z;
		}

		public void operator*=(Vec3 rhs) mut
		{
			x *= rhs.x;
			y *= rhs.y;
			z *= rhs.z;
		}

		public void operator/=(Vec3 rhs) mut
		{
			x /= rhs.x;
			y /= rhs.y;
			z /= rhs.z;
		}

		public static Vec3 operator+(Vec3 lhs, Vec3 rhs)
		{
			return .(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z);
		}

		public static Vec3 operator-(Vec3 lhs, Vec3 rhs)
		{
			return .(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z);
		}

		public override void ToString(String strBuffer)
		{
			strBuffer.AppendF("[{}, {}, {}]", x, y, z);
		}
	}
}
