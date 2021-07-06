# Fortran implementation of the geodesic routines in GeographicLib

The algorithms are documented in

* C. F. F. Karney,
  [Algorithms for geodesics](https://doi.org/10.1007/s00190-012-0578-z),
  J. Geodesy 87, 43-55 (2013);
  [Addenda](https://geographiclib.sourceforge.io/geod-addenda.html).

Here is the documentation on the
[application programming interface](https://geographiclib.sourceforge.io/html/Fortran/)

You can build the library and examples using cmake.  For example, on
Linux systems you might do:
```sh
cmake -B BUILD -S .
make -C BUILD
echo 30 0 29.5 179.5 | BUILD/tools/geodinverse
```

The two tools ngsforward and ngsinverse are replacements for the tools
FORWARD and INVERSE available from the
[NGS](http://www.ngs.noaa.gov/PC_PROD/Inv_Fwd/)
