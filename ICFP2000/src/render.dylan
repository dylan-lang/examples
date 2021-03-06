module: ray-tracer
synopsis: Recursive raytracing renderer
authors: Andreas Bogk, Jeff Dubrule, Bruce Hoult
copyright: this program may be freely used by anyone, for any purpose

define constant $eye-pos :: <3D-point> = point3D(0.0, 0.0, -1.0, 1.0);

// When recursing, move a tad in the direction of the ray your going
// for to avoid getting cut off by the surface you're leaving.
define constant $surface-acne-prevention-offset = 0.000000000001;

define method trace(ray :: <ray>, depth :: <integer>,
		    o :: <obj>, ambient :: <color>, 
		    lights :: <simple-object-vector>)
 => (color :: <color>);
  if (depth > 0)
    let (point, normal, surface, distance) = 
      intersection-before(o, ray, 1.0/0.0, #f);
    
    if (point)
      let point :: <3D-point> = point;
      let normal :: <3D-vector> = normal;
      let distance :: <fp> = distance;
      
      let reflection-color :: <color> = make-black();
      let surf :: <surface> = surface;
      if (surf.specular-coefficient > 0.0)
	let reflection-vector :: <3D-vector> = 2.0 * normal * 
	  (normal * -ray.ray-direction) + ray.ray-direction;
	let reflected-ray :: <ray> = make(<ray>,
					  direction: reflection-vector, 
					  position: point +
					    $surface-acne-prevention-offset *
					    normalize(reflection-vector));
	reflection-color := trace(reflected-ray, depth - 1, o, ambient, lights);
      end if; 
      
      let c = surf.color * (surf.diffusion-coefficient * ambient +
			      surf.specular-coefficient * reflection-color);

      for (l in lights)
	if (can-see(o, point, l))
	  c := c + surf.color * 
	    (intensity-on(l, point, normal) * surf.diffusion-coefficient
	       + phong-intensity-on(l, point, ray.ray-position, normal, surf.phong-coefficient)
	       * surf.specular-coefficient);
	end if;
      end for;  
      c;
    else
      make-black();
    end if;    
  else 
    make-black();
  end if;
end method trace;


define method render-image(o, depth :: <integer>, filename, ambient :: <color>, 
                           lights :: <simple-object-vector>, width :: <integer>,
                           height :: <integer>, fov :: <fp>)
  let canvas = make(<ppm-image>, filename: filename, depth: 255,
                    width: width, height: height);

  let world-width = 2.0 * tan(fov / 2.0);
  let world-height = world-width * as(<fp>, height) / as(<fp>, width);

  for (y from height - 1 above -1 by -1)
    for (x from 0 below width)
      // Add 0.5 to get to the middle of the pixel...
      let world-x :: <fp> = (as(<fp>, x - truncate/(width, 2)) + 0.5) 
        / as(<fp>, width) * world-width;
      let world-y :: <fp> = (as(<fp>, y - truncate/(height, 2)) + 0.5)
        / as(<fp>, height) * world-height;
      let ray = make(<ray>,
                     position: $eye-pos,
                     direction: point3D(world-x, world-y, 0.0, 1.0) - $eye-pos);
      write-pixel(canvas, trace(ray, depth, o, ambient, lights));
    end for;
  end for;

  close-ppm(canvas);
end method render-image;
