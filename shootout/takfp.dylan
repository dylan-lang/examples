module: takfp
use-libraries: common-dylan, io
use-modules: common-dylan, format-out

define function tak(X :: <float>, Y :: <float>, Z :: <float>)
    => result :: <float>;
  if (y >= x)
      z;
  else
      tak (tak((x - 1.0 ), y, z),
           tak((y - 1.0 ), z, x),
           tak((z - 1.0 ), x, y));
  end if;
end function tak;

define function takn (n :: <integer>) => result :: <float>;
  tak(3.0 * n, 2.0 * n, 1.0 * n);
end function takn;

begin
  let n = application-arguments()[0].string-to-integer;
  format-out("%.1f\n", takn(n));
end;

