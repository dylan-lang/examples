module: ary3

define constant <int-vector> = limited(<vector>, of: <integer>);

define function main(name, arguments)
	let n :: <integer> = string-to-integer(arguments[0]);

	let x = make(<int-vector>, size: n, fill: 0);
	let y = make(<int-vector>, size: n, fill: 0);

	for ( i from 0 below x.size)
		x[i] := i + 1;
	end for;
	
	for (k from 0 below 1000)
		for ( i from n - 1 above 0 by -1 )
			y[i] := y[i] + x[i];
		end for;
	end for;

	format-out("%d, %d\n", y[0], y[y.size - 1]);

end function main;

main(application-name(), application-arguments());
