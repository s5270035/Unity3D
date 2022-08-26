using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;

public class Sample {
	public Vector3 vec {get; set;}
	public float theta {get; set;}
	public float phi {get; set;}
	public List<float> coeff {get; set;}
	public Sample()
   	{
        coeff = new List<float>();
    }
}
public interface SphericalStrategy {
	float project(Sample s);
	void reconstruct(in List<Sample> samples);
}

public class ExampleLight : SphericalStrategy {
	public List<float> ci {get;}
	public ExampleLight()
   	{
        ci = new List<float>();
    }
	public float project(Sample s) {
		return Mathf.Max(0, 5f * Mathf.Cos(s.theta)-4) + Mathf.Max(0, -4*Mathf.Sin(s.theta-Mathf.PI) * Mathf.Cos(s.phi-2.5f)-3f);
	} 
	public void reconstruct(in List<Sample> samples) {
		var weight = 4f * Mathf.PI;
		int count = 0;
		ci.Clear();
		foreach(Sample sample in samples) {
			foreach(float c in sample.coeff){
				ci.Add(project(sample) * c);
				++count;
			}
		}
		var factor = weight / samples.Count;
		foreach(int i in Enumerable.Range(0, count)) {
			ci[i] = ci[i] * factor;
		}
	}
}
public class SH : MonoBehaviour
{
	Mesh mesh;
    Vector3[] vertices;
	Vector3[] normals;
	const int		SQRT_NB_SAMPLES = 20;
	const int		MAX_NB_SAMPLES = SQRT_NB_SAMPLES * SQRT_NB_SAMPLES;
	List<Sample> samples = new List<Sample>();
    // Start is called before the first frame update
    void Start()
    {
    	mesh = GetComponent<MeshFilter>().mesh;
        vertices = mesh.vertices;
		normals = mesh.normals;
        // create new colors array where the colors will be created.
        Color[] colors = new Color[vertices.Length]; 
		SH_setup_spherical_samples(ref samples, SQRT_NB_SAMPLES, 4);  
    }

    // Update is called once per frame
    void Update()
    {
        
    }
	Vector2 CartesianToPolar(Vector3 pos) {
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
    	float pmm = 1.0f;
    	
    	// First calculate P(m,m) since that is the only rule that requires results
		// from previous bands

		// Precalculate (1 - x^2)^0.5
		float somx2 = Mathf.Sqrt((1.0f-x)*(1.0f+x));
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
		float fact = 1.0f;
		if (m > 0) {
			for(int i=1; i<=m; ++i) {
				pmm *= (-fact) * somx2;
				fact += 2.0f;
			}
		}
		// rule 2
		if (l == m)
			return pmm;

		// rule 3 , use result of P(m,m) to calculate P(m,m+1)
		float pmmpl = x * (2.0f*m + 1.0f) * pmm;
		if (l == (m+1))
			return pmmpl;

		// rule 1, use rule 1 to calculate any remaining cases
		float pll = 0.0f;
		for(int ll=m+2; ll<=l; ++ll) {
			// Use result of two previous bands
			pll = ((2.0f*ll-1.0f)*x*pmmpl-(ll+m-1.0f)*pmm)/(ll-m);
			// Shift the previous two bands up
			pmm = pmmpl;
			pmmpl = pll;
		}
		return pll;
    }

    float K(int l, int m) 
    {
    	// Note that |m| is not used here as the SH function always passes positive m
    	return Mathf.Sqrt(((2f * l + 1f) * Factorial(l - m)) / (4f * Mathf.PI * Factorial(l + m)));
    }

    float SH_basis(int l, int m, float theta, float phi) {
    	if (m == 0)
    		return K(l, 0) * P(l, 0, Mathf.Cos(theta));
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
    	foreach(int a in Enumerable.Range(0, sqrt_n_samples)) {
    		foreach(int b in Enumerable.Range(0, sqrt_n_samples)) {
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
    			foreach(int l in Enumerable.Range(0, n_bands)) {
    				foreach(int m in Enumerable.Range(-l, l+1)) {
    					// int index = l*(l+1)+m;
    					float coeff = SH_basis(l, m, theta, phi);
						sample.coeff.Add(coeff);
    			    }
    		 	}
				samples.Add(sample);
    	    }
        }
    }
}

