module: vrml-model


define abstract class <node> (<object>)
end class <node>;

// <child-vector> can contain any of
// Anchor, Background, Billboard, Collision, ColorInterpolator, CoordinateInterpolator,
// CylinderSensor, DirectionalLight, Fog, Group, Inline, LOD, NavigationInfo,
// NormalInterpolator, OrientationInterpolator, PlaneSensor, PointLight,
// PositionInterpolator, ProximitySensor, ScalarInterpolator, Script, Shape, Sound,
// SpotLight, SphereSensor, Switch, TimeSensor, TouchSensor, Transform, Viewpoint,
// VisibilitySensor, WorldInfo

define constant <child-vector> = <simple-object-vector>;

define class <container-node> (<node>)
  slot children :: <simple-object-vector>, required-init-keyword: children:;
end class <container-node>;

define class <my-indexed-face-set> (<node>)
  slot ccw :: <boolean> = #f, init-keyword: ccw:; // orientation of faces
  slot points, init-keyword: points:;
  slot polygon-indices, init-keyword: indices:;
  slot face-normals :: false-or(<vector>) = #f, init-keyword: face-normals:;
  slot vertex-normals :: false-or(<vector>) = #f, init-keyword: vertex-normals:;
  slot crease-angle :: <float> = 0.0, init-keyword: crease-angle:;
end class <my-indexed-face-set>;

define class <indexed-face-set> (<node>)
  slot color :: false-or(<color>) = #f, init-keyword: color:;
  slot coord :: <simple-object-vector> = #[], init-keyword: coord:;
  slot normal :: false-or(<simple-object-vector>) = #f, init-keyword: normal:;
  slot tex-coord :: false-or(<collection>) = #f, init-keyword: tex-coord:;
  slot ccw :: <boolean> = #t, init-keyword: ccw:;
  slot color-index :: <collection> = #[], init-keyword: color-index:;
  slot color-per-vertex :: <boolean> = #t, init-keyword: color-per-vertex:;
  slot convex :: <boolean> = #t, init-keyword: convex:;
  slot coord-index :: <simple-object-vector> = #[], init-keyword: coord-index:;
  slot crease-angle :: <float> = 0.0, init-keyword: crease-angle:;
  slot normal-index :: false-or(<simple-object-vector>) = #f, init-keyword: normal-index:;
  slot normal-per-vertex :: <boolean> = #t, init-keyword: normal-per-vertex:;
  slot solid :: <boolean> = #t, init-keyword: solid:;
  slot tex-coord-index :: <collection> = #[], init-keyword: tex-coord-index:;
  slot ifs-id :: <integer> = 0;
end class <indexed-face-set>;

define class <vertex> (<object>)
  slot v :: <3d-point>, required-init-keyword: v:; // position vector
  slot neighbouring-triangles :: <collection> = #();
  slot normal :: false-or(<3d-vector>) = #f, init-keyword: normal:; 
end class <vertex>;

define class <triangle> (<object>)
  slot vertices :: <collection>, required-init-keyword: vertices:;
  slot normal :: false-or(<3d-vector>) = #f, init-keyword: normal:;
end class <triangle>;

define method initialize(ifs :: <my-indexed-face-set>, #key, #all-keys)
 => ()
  next-method();
/*
        // need to translate polygons from -1 delimited list of points to
        // list of lists of points
        let polys =
          begin
            if (coordIndex)
              dd("reshaping polygons\n");
              let coordIndex :: <stretchy-object-vector> = coordIndex;
              let polys = make(<stretchy-vector>,, 
                               size: truncate/(coordIndex.size, 4));
              let start = 0;
              local
                method addpoly(from :: <integer>, to :: <integer>)
                  let poly = make(<vector>, size: to - from);
                  for (i from from below to)
                    poly[i - from] := coordIndex[i];
                  end;
                  add!(polys, poly);
                  start := to + 1;
                end method;                  
              for(e :: <integer> in coordIndex, i from 0)
                if (e == -1)
                  addpoly(start, i);
                end;
              end;
              if (coordIndex.last ~== -1)
                addpoly(start, coordIndex.size);
              end;
              polys;
            end;
          end;
*/
  unless(ifs.face-normals)
    ifs.face-normals := make(<vector>, size: ifs.polygon-indices.size);
    for(p keyed-by i in ifs.polygon-indices)
      let normal = cross-product(ifs.points[p[1]] - ifs.points[p[0]],
                                 ifs.points[p[2]] - ifs.points[p[1]]);
      
      if(~ifs.ccw)
        normal := -1.0 * normal;
      end if;
      ifs.face-normals[i] := normalize(normal);
    end for;
  end unless;
  unless(ifs.vertex-normals)
    ifs.vertex-normals := make(<vector>, size: ifs.polygon-indices.size);
    let cos-crease-angle = cos(ifs.crease-angle);
    for(p keyed-by i in ifs.polygon-indices)
      ifs.vertex-normals[i] := make(<vector>, size: p.size);
      for(j from 0 below p.size)
        let adjoining-faces = #();
        for(k from 0 below ifs.polygon-indices.size)
          if((i ~= k) 
               & member?(ifs.polygon-indices[i][j], ifs.polygon-indices[k])
               & (ifs.face-normals[i] * ifs.face-normals[k] > cos-crease-angle))
            adjoining-faces := add(adjoining-faces, k);
          end if;
        end for;
        let sum = ifs.face-normals[i];
        for(k in adjoining-faces)
          sum := sum + ifs.face-normals[k];
        end for;
          
        ifs.vertex-normals[i][j] := normalize(sum);
      end for;
    end for;
  end unless;
end method initialize;

define class <transform> (<container-node>)
  slot center :: false-or(<3d-vector>) = #f, init-keyword: center:;
  slot rotation :: false-or(<3d-rotation>) = #f, init-keyword: rotation:;
  slot scale :: false-or(<3d-vector>) = #f, init-keyword: scale:;
  slot scale-orientation :: false-or(<3d-rotation>) = #f, init-keyword: scale-orientation:;
  slot translation :: false-or(<3d-vector>) = #f, init-keyword: translation:;
end class <transform>;

define constant <geometry-node> = <node>;
// IndexedFaceSet, Box, Cone, Cylinder, ElevationGrid, Extrusion, IndexedLineSet, PointSet, Sphere, Text

define class <shape> (<node>)
  slot appearance :: <appearance>, required-init-keyword: appearance:;
  slot geometry :: <geometry-node>, required-init-keyword: geometry:;
end class <shape>;

define class <appearance> (<node>)
  slot material = #f, init-keyword: material:;
  slot texture = #f, init-keyword: texture:;
  slot texture-transform = #f, init-keyword: texture-transform:;
end class <appearance>;

define class <texture> (<node>)
  slot pixel-data, init-keyword: pixel-data:;
  slot width :: <integer>, init-keyword: width:;
  slot height :: <integer>, init-keyword: height:;
  slot depth :: <integer>, init-keyword: depth:;
  slot repeat-s :: <boolean> = #f, init-keyword: repeat-s:;
  slot repeat-t :: <boolean> = #f, init-keyword: repeat-t:;
  slot texture-id :: false-or(<integer>) = #f;
end class <texture>;

define constant $texture-cache = make(<string-table>);

define function lookup-texture(url :: <string>)
  let cached-texture = element($texture-cache, url, default: #f);
  if(cached-texture)
    apply(values, cached-texture)
  else
    let (#rest data) = read-png(url);
    $texture-cache[url] := data;
    apply(values, data);
  end if;
end function lookup-texture;

define method initialize(t :: <texture>, 
                         #key file-name :: false-or(<string>), 
                         #all-keys) => (<texture>);
  next-method();
  if(file-name)
    let (pixel-data, width, height, depth) = lookup-texture(file-name);
    t.pixel-data := pixel-data;
    t.width := width; 
    t.height := height;
    t.depth := depth;
  end if;
end method initialize;

define class <material> (<node>)
  slot ambient-intensity :: <float>, init-keyword: ambient-intensity:;
  slot diffuse-color     :: <color>, init-keyword: diffuse-color:;
  slot emissive-color    :: <color>, init-keyword: emissive-color:;
  slot shininess         :: <float>, init-keyword: shininess:;
  slot specular-color    :: <color>, init-keyword: specular-color:;
  slot transparency      :: <float>, init-keyword: transparency:;
end class <material>;


define class <line-grid> (<node>)
end class <line-grid>;

define class <sphere> (<node>)
end class <sphere>;

define class <camera> (<node>)
  slot eye-position :: <3d-point> = 3d-point(0.0, 1.7, 3.0), init-keyword: position:;
  slot looking-at :: <3d-point> = 3d-point(0.0, 0.0, 1.0), init-keyword: looking-at:;
  slot up :: <3d-vector> = 3d-vector(0.0, 1.0, 0.0), init-keyword: up:;
//  slot angle :: <float> = 0.0;
  slot viewport :: <vector> = #[500, 500], init-keyword: viewport:;
end class <camera>;

define class <light> (<node>)
  slot light-id;
  class slot next-free-id = 0;
  slot ambient :: false-or(<vector>) = #f, init-keyword: ambient:;
  slot diffuse :: false-or(<vector>) = #f, init-keyword: diffuse:;
  slot specular :: false-or(<vector>) = #f, init-keyword: specular:;
end class <light>;

define class <directional-light> (<light>)
  slot spot-direction :: <3d-vector> = 3d-vector(0.0, 0.0, -1.0), init-keyword: direction:;
end class <directional-light>;

define class <pointlight> (<light>)
  slot light-position :: <3d-point> = 3d-point(0.0, 0.0, 0.0, 1.0), init-keyword: position:;
end class <pointlight>;

define class <spotlight> (<directional-light>, <pointlight>)
end class <spotlight>;

define method initialize(light :: <spotlight>, #key, #all-keys)
  next-method();
  light.light-id := light.next-free-id;
  light.next-free-id := light.next-free-id + 1;
end method initialize;

define class <on-screen-display> (<container-node>)
end class <on-screen-display>;

define class <2d-translation> (<node>)
  slot translation :: <vector> = #[0, 0], init-keyword: translation:;
end class <2d-translation>;

define class <text> (<node>)
  slot text :: <string> = "", init-keyword: text:;
end class <text>;

define class <2d-image> (<texture>)
end class <2d-image>;

define generic preorder-traversal(node :: <node>, function :: <function>);

define method preorder-traversal(node :: <node>, function :: <function>)
  function(node);
end method preorder-traversal;

define method preorder-traversal(node :: <container-node>, 
                                 function :: <function>)
  function(node);
  for(i in node.children)
    preorder-traversal(i, function);
  end for;
end method preorder-traversal;
