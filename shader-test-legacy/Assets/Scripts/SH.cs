using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;
using Coeff = System.Collections.Generic.List<float>;
public class Sample {
	public Vector3 vec {get; set;}
	public float theta {get; set;}
	public float phi {get; set;}
	public Coeff coeff {get; set;}
	public Sample()
   	{
        coeff = new Coeff();
    }
}
public static class Utilities {
	public static Vector2 CartesianToPolar(Vector3 pos) {
		var polar = new Vector2();
		// calc longitude
		polar.y = Mathf.Atan2(pos.x, pos.z);

		// this is easier to write and read than sqrt(pow(x,2), pow(y, 2))
		var len = new Vector2(pos.x, pos.z);
		var xzLen = len.magnitude;
		// atan2 does the magic
		polar.x = Mathf.Atan2(-pos.y, xzLen);

		// convert to deg
		// polar *= Mathf.Rad2Deg;
		return polar;
	}
}
public abstract class SphericalStrategy {
	public virtual void proccess(in Sample s, in Vector3 pos, in Vector3 normal, ref Coeff coeff) {
		Debug.Log("override me");
	}
}

public class DeffuseUnShadowed : SphericalStrategy {
	public override void proccess(in Sample s, in Vector3 pos, in Vector3 normal, ref Coeff coeff) {
		var n_bases = s.coeff.Count;
		float H =  Vector3.Dot(s.vec, normal);
		if (H>0f) {
			for(int i=0; i<n_bases; ++i) {
			   coeff[i] += H * s.coeff[i] * (1f/Mathf.PI);
			}
		}
	} 
}
public class AmbientOcclusion : SphericalStrategy {
	public override void proccess(in Sample s, in Vector3 pos, in Vector3 normal, ref Coeff coeff) {
		var n_bases = s.coeff.Count;
		float H =  Vector3.Dot(s.vec, normal);
		//Debug.Log(normal);
		if (H>0f) {
			// RaycastHit hit;
			for(int i=0; i<n_bases; ++i) {
				// if(!Physics.Raycast(pos+2f*float.Epsilon*normal, s.vec, out hit, 2f)) {
				// 	coeff[i] += H * s.coeff[i] * (1f / Mathf.PI);
				// }	
				Debug.Log(H * s.coeff[i]);		   
			}
			
		}
	} 
}
public class SH : MonoBehaviour
{
	public int bands;
	Mesh mesh;
    Vector3[] vertices;
	Vector3[] normals;
	const int		SQRT_NB_SAMPLES = 20;
	const int		MAX_NB_SAMPLES = SQRT_NB_SAMPLES * SQRT_NB_SAMPLES;
	List<Sample> samples = new List<Sample>();
	
	List<Coeff> ci = new List<Coeff>();
	List<Coeff> li = new List<Coeff>();
	float[] factorial = new float[] {
		1.0f,  
		1.0f,
		2.0f,
		6.0f,
		24.0f,
		120.0f,
		720.0f,
		5040.0f,
		40320.0f,
		362880.0f,
		3628800.0f,
		39916800.0f,
		479001600.0f,
		6227020800.0f,
		87178291200.0f,
		1307674368000.0f,
		20922789888000.0f,
		355687428096000.0f,
		6402373705728000.0f,
		121645100408832000.0f,
		2432902008176640000.0f,
		51090942171709440000.0f,
		1124000727777607680000.0f,
		25852016738884976640000.0f,
		620448401733239439360000.0f,
		15511210043330985984000000.0f,
		403291461126605635584000000.0f,
		10888869450418352160768000000.0f,
		304888344611713860501504000000.0f,
		8841761993739701954543616000000.0f,
		265252859812191058636308480000000.0f,
		8222838654177922817725562880000000.0f,
		263130836933693530167218012160000000.0f,
		8683317618811886495518194401280000000.0f
	};

    // Start is called before the first frame update
    void Start()
    {
    	mesh = GetComponent<MeshFilter>().mesh;
        vertices = mesh.vertices;
		normals = mesh.normals;
        // create new colors array where the colors will be created.
		SH_setup_spherical_samples(ref samples, SQRT_NB_SAMPLES, bands);
		DeffuseUnShadowed diffuse_unshadowed = new DeffuseUnShadowed();
		AmbientOcclusion ambient_occlusion = new AmbientOcclusion();
		for(int i=0; i<vertices.Length; ++i) {
			ci.Add(new Coeff(new float[bands*bands]));
		}
		reconstruct(in mesh, in samples, ref ci, ambient_occlusion);
		draw();
    }
    // Update is called once per frame
    void Update()
    {
        
    }
    // Basic integer factorial
	int Factorial(int v)
	{
		if (v == 0)
			return (1);

		int result = v;
		while (--v > 0)
			result *= v;
		return (result);
	}

    float P(int l, int m, float x)
    {
    	/*
    	  evaluate an Associated Legendre Polynomial P(l,m,x) at x
    	*/
    	// Start with P(0,0) at 1
    	float pmm = 1f;
    	
    	// First calculate P(m,m) since that is the only rule that requires results
		// from previous bands

		// Precalculate (1 - x^2)^0.5
		// float somx2 = Mathf.Sqrt((1f-x)*(1f+x));
		
		// This calculates P(m,m). There are three terms in rule 2 that are being iteratively multiplied:
		//
		// 0: -1^m
		// 1: (2m-1)!!
		// 2: (1-x^2)^(m/2)
		//
		// Term 2 has been partly precalculated and the iterative multiplication by itself m times
		// completes the term.
		// The result of 2m-1 is always odd so the double factorial calculation multiplies every odd
		// number below 2m-1 together. So, term 3 is calculated using the 'fact' variable.
		
		if (m > 0) {
			float somx2 = Mathf.Sqrt((1f-x)*(1f+x));
			float fact = 1f;
			for(int i=1; i<=m; ++i) {
				pmm *= (-fact) * somx2;
				fact += 2f;
			}
		}
		// rule 2
		if (l == m)
			return pmm;

		// rule 3 , use result of P(m,m) to calculate P(m,m+1)
		float pmmpl = x * (2f*m + 1f) * pmm;
		if (l == (m+1))
			return pmmpl;

		// rule 1, use rule 1 to calculate any remaining cases
		float pll = 0.0f;
		for(int ll=m+2; ll<=l; ++ll) {
			// Use result of two previous bands
			pll = ((2f*ll-1.0f)*x*pmmpl-(ll+m-1f)*pmm)/(ll-m);
			// Shift the previous two bands up
			pmm = pmmpl;
			pmmpl = pll;
		}
		return pll;
    }

    float K(int l, int m) 
    {
    	// Note that |m| is not used here as the SH function always passes positive m
    	return Mathf.Sqrt(((2f * l + 1f) * factorial[l - m]) / (4f * Mathf.PI * factorial[l + m]));
    }

    float SH_basis(int l, int m, float theta, float phi) {
    	if (m == 0)
    		return K(l, 0) * P(l, m, Mathf.Cos(theta));
    	else if(m > 0)
    		return Mathf.Sqrt(2f) * K(l, m) * Mathf.Cos(m * phi) * P(l, m, Mathf.Cos(theta));
    	else
    		return Mathf.Sqrt(2f) * K(l, -m) * Mathf.Sin(-m * phi) * P(l, -m, Mathf.Cos(theta));
    }
    void SH_setup_spherical_samples(ref List<Sample> samples, int sqrt_n_samples, int n_bands) {
    	/*
    	fill an N*N*2 array with uniformly distributed 
    	samples across the sphere using jittered stratification
    	*/
    	float oneoverN = 1f/sqrt_n_samples;
    	for(int a = 0; a <  sqrt_n_samples; ++a) {
    		for(int b = 0; b < sqrt_n_samples; ++b) {
    			// generate unbiased distribution of spherical coords
    			float x = (a + Random.value) * oneoverN;  // do not reuse results 
    			float y = (b + Random.value) * oneoverN;
    			float theta = 2f * Mathf.Acos(Mathf.Sqrt(1f - x));
    			float phi = 2f * Mathf.PI * y;
    			// convert spherical coords to unit vector
    			Vector3 vec = new Vector3(Mathf.Sin(theta)*Mathf.Cos(phi),
    				                      Mathf.Sin(theta)*Mathf.Sin(phi),
    				                      Mathf.Cos(theta));
				var sample = new Sample();
				sample.phi = phi;
				sample.theta = theta;
				sample.vec = vec;
    			for(int l = 0; l < n_bands; ++l) {
    				for(int m = -l; m <=l; ++m) {
    					int index = l*(l+1)+m;
    					float coeff = SH_basis(l, m, theta, phi);
						sample.coeff.Add(coeff);
    			    }
    		 	}
				samples.Add(sample);
    	    }
        }
    }
	void reconstruct(in Mesh mesh, in List<Sample> samples, ref List<Coeff> ci, SphericalStrategy policy) {
		var weight = 4f * Mathf.PI;
		Vector3[] vertices = mesh.vertices;
		int n_bases = samples[0].coeff.Count;
		for (var i = 0; i < vertices.Length; ++i) {	
			Coeff coeff = new Coeff(new float[n_bases]);		
			foreach(Sample sample in samples) {
				policy.proccess(sample, vertices[i], mesh.normals[i], ref coeff);
				ci[i] = coeff;
			}
			var factor = weight / samples.Count;
			for(int k=0; k < n_bases; ++k) {
				ci[i][k] = ci[i][k] * factor;
			}
		} 
	}
	void draw() {
		var NB_BASES = bands * bands;
		var colors = new Color[vertices.Length]; 
	
		for (var i = 0; i < vertices.Length; ++i) {
			//foreach(Sample s in samples) {
				float color = 0f;
				for(int k = 0; k<NB_BASES; ++k){
					color += ci[i][k];
				}
				colors[i] = new Color(color, color, color);
			//}

		}
		mesh.colors = colors;
	}
}

