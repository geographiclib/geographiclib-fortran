* This is a Fortran implementation of the geodesic algorithms described
* in
*
*   C. F. F. Karney,
*   Algorithms for geodesics,
*   J. Geodesy (2012);
*   http://dx.doi.org/10.1007/s00190-012-0578-z
*   Addenda: http://geographiclib.sf.net/geod-addenda.html
*
* The principal advantages of these algorithms over previous ones (e.g.,
* Vincenty, 1975) are
*   * accurate to round off for abs(f) < 1/50;
*   * the solution of the inverse problem is always found;
*   * differential and integral properties of geodesics are computed.
*
* The shortest path between two points on the ellipsoid at (lat1, lon1)
* and (lat2, lon2) is called the geodesic.  Its length is s12 and the
* geodesic from point 1 to point 2 has forward azimuths azi1 and azi2 at
* the two end points.
*
* Traditionally two geodesic problems are considered:
*   * the direct problem -- given lat1, lon1, s12, and azi1, determine
*     lat2, lon2, and azi2.  This is solved by the subroutine direct.
*   * the inverse problem -- given lat1, lon1, lat2, lon2, determine
*     s12, azi1, and azi2.  This is solved by the subroutine invers.
*
* The calling sequence for direct and invers is specified by the
* interface block
*
*       interface
*
*         subroutine direct(a, f, lat1, lon1, azi1, s12a12, arcmod,
*      +      lat2, lon2, azi2, omask, a12s12, m12, MM12, MM21, SS12)
*         double precision, intent(in) :: a, f, lat1, lon1, azi1, s12a12
*         logical, intent(in) :: arcmod
*         integer, intent(in) :: omask
*         double precision, intent(out) :: lat2, lon2, azi2
* * optional output (depending on omask)
*         double precision, intent(out) :: a12s12, m12, MM12, MM21, SS12
*         end subroutine direct
*
*         subroutine invers(a, f, lat1, lon1, lat2, lon2,
*      +      s12, azi1, azi2, omask, a12, m12, MM12, MM21, SS12)
*         double precision, intent(in) :: a, f, lat1, lon1, lat2, lon2
*         integer, intent(in) :: omask
*         double precision, intent(out) :: s12, azi1, azi2
* * optional output (depending on omask)
*         double precision, intent(out) :: a12, m12, MM12, MM21, SS12
*         end subroutine invers
*
*         subroutine area(a, f, lats, lons, n, S, P)
*         integer, intent(in) :: n
*         double precision, intent(in) :: a, f, lats(n), lons(n)
*         double precision, intent(out) :: S, P
*         end subroutine area
*
*       end interface
*
* The ellipsoid is specified by its equatorial radius a (typically in
* meters) and flattening f.  The routines are accurate to round off with
* double precision arithmetic provided that abs(f) < 1/50; for the WGS84
* ellipsoid, the errors are less than 15 nanometers.  (Reasonably
* accurate results are obtained for abs(f) < 1/5.)  Latitudes,
* longitudes, and azimuths are in degrees.  Latitudes must lie in
* [-90,90] and longitudes and azimuths must lie in [-540,540).  The
* returned values for longitude and azimuths are in [-180,180).  The
* distance s12 is measured in meters (more precisely the same units as
* a).
*
* The routines also calculate several other quantities of interest
*   * SS12 is the area between the geodesic from point 1 to point 2 and
*     the equator; i.e., it is the area, measured counter-clockwise, of
*     the quadrilateral with corners (lat1,lon1), (0,lon1), (0,lon2),
*     and (lat2,lon2).  It is given in meters^2.
*   * m12, the reduced length of the geodesic is defined such that if
*     the initial azimuth is perturbed by dazi1 (radians) then the
*     second point is displaced by m12 dazi1 in the direction
*     perpendicular to the geodesic.  m12 is given in meters.  On a
*     curved surface the reduced length obeys a symmetry relation, m12 +
*     m21 = 0.  On a flat surface, we have m12 = s12.
*   * MM12 and MM21 are geodesic scales.  If two geodesics are parallel
*     at point 1 and separated by a small distance dt, then they are
*     separated by a distance MM12 dt at point 2.  MM21 is defined
*     similarly (with the geodesics being parallel to one another at
*     point 2).  MM12 and MM21 are dimensionless quantities.  On a flat
*     surface, we have MM12 = MM21 = 1.
*   * a12 is the arc length on the auxiliary sphere.  This is a
*     construct for converting the problem to one in spherical
*     trigonometry.  a12 is measured in degrees.  The spherical arc
*     length from one equator crossing to the next is always 180
*     degrees.
*
* Whether or not these quantities are return depends on the value of
* omask which is a integer bit mask with the following bit assignments
*   * 1 return a12
*   * 2 return m12
*   * 4 return MM12 and MM21
*   * 8 return SS12
*
* Subroutine direct accepts an input parameter arcmod.  If this is false
* (the "normal" setting) then the length of the geodesic is specified by
* s12 and a12 is returned.  Setting arcmod = true, allows the length to
* be specified as a12 (the argument s12a12) and the "real" length (in
* meters) is returned as the argument a12s12 (provided that the 1 bit of
* omask is set).
*
* Subroutine area computes the area of a geodesic polygon with n
* vertices given by the areas lats and lons.  It returns the area in S
* and the perimeter in P.  The polygon must be simple; counter-clockwise
* traversal counts as a positive area.
*
* Copyright (c) Charles Karney (2012) <charles@karney.com> and licensed
* under the MIT/X11 License.  For more information, see
* http://geographiclib.sourceforge.net/
*
* This file was distributed with GeographicLib 1.28.

      block data geodat
      double precision dblmin, dbleps, pi, degree, tiny,
     +    tol0, tol1, tol2, tolb, xthrsh
      integer digits, maxit1, maxit2
      logical init
      data init /.false./
      common /geocom/ dblmin, dbleps, pi, degree, tiny,
     +    tol0, tol1, tol2, tolb, xthrsh, digits, maxit1, maxit2, init
      end

      subroutine geoini
      double precision dblmin, dbleps, pi, degree, tiny,
     +    tol0, tol1, tol2, tolb, xthrsh
      integer digits, maxit1, maxit2
      logical init
      common /geocom/ dblmin, dbleps, pi, degree, tiny,
     +    tol0, tol1, tol2, tolb, xthrsh, digits, maxit1, maxit2, init

      digits = 53
      dblmin = 0.5d0**1022
      dbleps = 0.5d0**(digits-1)

      pi = atan2(0.0d0, -1.0d0)
      degree = pi/180
      tiny = sqrt(dblmin)
      tol0 = dbleps
* Increase multiplier in defn of tol1 from 100 to 200 to fix inverse case
* 52.784459512564 0 -52.784459512563990912 179.634407464943777557
* which otherwise failed for Visual Studio 10 (Release and Debug)
      tol1 = 200 * tol0
      tol2 = sqrt(tol0)
* Check on bisection interval
      tolb = tol0 * tol2
      xthrsh = 1000 * tol2
      maxit1 = 20
      maxit2 = maxit1 + digits + 10

      init = .true.

      return
      end

      subroutine direct(a, f, lat1, lon1, azi1, s12a12, arcmod,
     +    lat2, lon2, azi2, omask, a12s12, m12, MM12, MM21, SS12)
* input
      double precision a, f, lat1, lon1, azi1, s12a12
      logical arcmod
      integer omask
* output
      double precision lat2, lon2, azi2
* optional output
      double precision a12s12, m12, MM12, MM21, SS12

      integer ord, nC1, nC1p, nC2, nA3, nA3x, nC3, nC3x, nC4, nC4x
      parameter (ord = 6, nC1 = ord, nC1p = ord,
     +    nC2 = ord, nA3 = ord, nA3x = nA3,
     +    nC3 = ord, nC3x = (nC3 * (nC3 - 1)) / 2,
     +    nC4 = ord, nC4x = (nC4 * (nC4 + 1)) / 2)
      double precision A3x(0:nA3x-1), C3x(0:nC3x-1), C4x(0:nC4x-1),
     +    C1a(nC1), C1pa(nC1p), C2a(nC2), C3a(nC3-1), C4a(0:nC4-1)

      double precision csmgt, atanhx, hypotx,
     +    AngNm, AngNm2, AngRnd, TrgSum, A1m1f, A2m1f, A3f
      logical arcp, redlp, scalp, areap
      double precision e2, f1, ep2, n, b, c2,
     +    lon1x, azi1x, phi, alp1, salp0, calp0, k2, eps,
     +    salp1, calp1, ssig1, csig1, cbet1, sbet1, dn1, somg1, comg1,
     +    salp2, calp2, ssig2, csig2, sbet2, cbet2, dn2, somg2, comg2,
     +    ssig12, csig12, salp12, calp12, omg12, lam12, lon12,
     +    sig12, stau1, ctau1, tau12, s12a, t, s, c, serr,
     +    A1m1, A2m1, A3c, A4, AB1, AB2,
     +    B11, B12, B21, B22, B31, B41, B42, J12

      double precision dblmin, dbleps, pi, degree, tiny,
     +    tol0, tol1, tol2, tolb, xthrsh
      integer digits, maxit1, maxit2
      logical init
      common /geocom/ dblmin, dbleps, pi, degree, tiny,
     +    tol0, tol1, tol2, tolb, xthrsh, digits, maxit1, maxit2, init

      if (.not.init) call geoini

      e2 = f * (2 - f)
      ep2 = e2 / (1 - e2)
      f1 = 1 - f
      n = f / (2 - f)
      b = a * f1
      c2 = 0

      arcp = mod(omask/1, 2) == 1
      redlp = mod(omask/2, 2) == 1
      scalp = mod(omask/4, 2) == 1
      areap = mod(omask/8, 2) == 1

      if (areap) then
        if (e2 .eq. 0) then
          c2 = a**2
        else if (e2 .gt. 0) then
          c2 = (a**2 + b**2 * atanhx(sqrt(e2)) / sqrt(e2)) / 2
        else
          c2 = (a**2 + b**2 * atan(sqrt(abs(e2))) / sqrt(abs(e2))) / 2
        end if
      end if

      call A3cof(n, A3x)
      call C3cof(n, C3x)
      if (areap) call C4cof(n, C4x)

* Guard against underflow in salp0
      azi1x = AngRnd(AngNm(azi1))
      lon1x = AngNm(lon1)

* alp1 is in [0, pi]
      alp1 = azi1x * degree
* Enforce sin(pi) == 0 and cos(pi/2) == 0.  Better to face the ensuing
* problems directly than to skirt them.
      salp1 = csmgt(0d0, sin(alp1), azi1x .eq. -180)
      calp1 = csmgt(0d0, cos(alp1), abs(azi1x) .eq. 90)

      phi = lat1 * degree
* Ensure cbet1 = +dbleps at poles
      sbet1 = f1 * sin(phi)
      cbet1 = csmgt(tiny, cos(phi), abs(lat1) .eq. 90)
      call Norm(sbet1, cbet1)
      dn1 = sqrt(1 + ep2 * sbet1**2)

* Evaluate alp0 from sin(alp1) * cos(bet1) = sin(alp0),
* alp0 in [0, pi/2 - |bet1|]
      salp0 = salp1 * cbet1
* Alt: calp0 = hypot(sbet1, calp1 * cbet1).  The following
* is slightly better (consider the case salp1 = 0).
      calp0 = hypotx(calp1, salp1 * sbet1)
* Evaluate sig with tan(bet1) = tan(sig1) * cos(alp1).
* sig = 0 is nearest northward crossing of equator.
* With bet1 = 0, alp1 = pi/2, we have sig1 = 0 (equatorial line).
* With bet1 =  pi/2, alp1 = -pi, sig1 =  pi/2
* With bet1 = -pi/2, alp1 =  0 , sig1 = -pi/2
* Evaluate omg1 with tan(omg1) = sin(alp0) * tan(sig1).
* With alp0 in (0, pi/2], quadrants for sig and omg coincide.
* No atan2(0,0) ambiguity at poles since cbet1 = +dbleps.
* With alp0 = 0, omg1 = 0 for alp1 = 0, omg1 = pi for alp1 = pi.
      ssig1 = sbet1
      somg1 = salp0 * sbet1
      csig1 = csmgt(cbet1 * calp1, 1d0, sbet1 .ne. 0 .or. calp1 .ne. 0)
      comg1 = csig1
* sig1 in (-pi, pi]
      call Norm(ssig1, csig1)
* Geodesic::Norm(somg1, comg1); -- don't need to normalize!

      k2 = calp0**2 * ep2
      eps = k2 / (2 * (1 + sqrt(1 + k2)) + k2)

      A1m1 = A1m1f(eps)
      call C1f(eps, C1a)
      B11 = TrgSum(.true., ssig1, csig1, C1a, nC1)
      s = sin(B11)
      c = cos(B11)
* tau1 = sig1 + B11
      stau1 = ssig1 * c + csig1 * s
      ctau1 = csig1 * c - ssig1 * s
* Not necessary because C1pa reverts C1a
*    B11 = -TrgSum(true, stau1, ctau1, C1pa, nC1p)

      if (.not. arcmod) call C1pf(eps, C1pa)

      if (redlp .or. scalp) then
        A2m1 = A2m1f(eps)
        call C2f(eps, C2a)
        B21 = TrgSum(.true., ssig1, csig1, C2a, nC2)
      else
* Suppress bogus warnings about unitialized variables
        A2m1 = 0
        B21 = 0
      end if

      call C3f(eps, C3x, C3a)
      A3c = -f * salp0 * A3f(eps, A3x)
      B31 = TrgSum(.true., ssig1, csig1, C3a, nC3-1)

      if (areap) then
        call C4f(eps, C4x, C4a)
* Multiplier = a^2 * e^2 * cos(alpha0) * sin(alpha0)
        A4 = a**2 * calp0 * salp0 * e2
        B41 = TrgSum(.false., ssig1, csig1, C4a, nC4)
      else
* Suppress bogus warnings about unitialized variables
        A4 = 0
        B41 = 0
      end if

      if (arcmod) then
* Interpret s12a12 as spherical arc length
        sig12 = s12a12 * degree
        s12a = abs(s12a12)
        s12a = s12a - 180 * aint(s12a / 180)
        ssig12 =  csmgt(0d0, sin(sig12), s12a .eq.  0)
        csig12 =  csmgt(0d0, cos(sig12), s12a .eq. 90)
* Suppress bogus warnings about unitialized variables
        B12 = 0
      else
* Interpret s12a12 as distance
        tau12 = s12a12 / (b * (1 + A1m1))
        s = sin(tau12)
        c = cos(tau12)
* tau2 = tau1 + tau12
        B12 = - TrgSum(.true.,
     +      stau1 * c + ctau1 * s, ctau1 * c - stau1 * s, C1pa, nC1p)
        sig12 = tau12 - (B12 - B11)
        ssig12 = sin(sig12)
        csig12 = cos(sig12)
        if (abs(f) .gt. 0.01d0) then
* Reverted distance series is inaccurate for |f| > 1/100, so correct
* sig12 with 1 Newton iteration.  The following table shows the
* approximate maximum error for a = WGS_a() and various f relative to
* GeodesicExact.
*     erri = the error in the inverse solution (nm)
*     errd = the error in the direct solution (series only) (nm)
*     errda = the error in the direct solution (series + 1 Newton) (nm)
*
*       f     erri  errd errda
*     -1/5    12e6 1.2e9  69e6
*     -1/10  123e3  12e6 765e3
*     -1/20   1110 108e3  7155
*     -1/50  18.63 200.9 27.12
*     -1/100 18.63 23.78 23.37
*     -1/150 18.63 21.05 20.26
*      1/150 22.35 24.73 25.83
*      1/100 22.35 25.03 25.31
*      1/50  29.80 231.9 30.44
*      1/20   5376 146e3  10e3
*      1/10  829e3  22e6 1.5e6
*      1/5   157e6 3.8e9 280e6
          ssig2 = ssig1 * csig12 + csig1 * ssig12
          csig2 = csig1 * csig12 - ssig1 * ssig12
          B12 = TrgSum(.true., ssig2, csig2, C1a, nC1)
          serr = (1 + A1m1) * (sig12 + (B12 - B11)) - s12a12 / b
          sig12 = sig12 - serr / sqrt(1 + k2 * ssig2**2)
          ssig12 = sin(sig12)
          csig12 = cos(sig12)
* Update B12 below
        end if
      end if

* sig2 = sig1 + sig12
      ssig2 = ssig1 * csig12 + csig1 * ssig12
      csig2 = csig1 * csig12 - ssig1 * ssig12
      dn2 = sqrt(1 + k2 * ssig2**2)
      if (arcmod .or. abs(f) .gt. 0.01d0)
     +    B12 = TrgSum(.true., ssig2, csig2, C1a, nC1)
      AB1 = (1 + A1m1) * (B12 - B11)

* sin(bet2) = cos(alp0) * sin(sig2)
      sbet2 = calp0 * ssig2
* Alt: cbet2 = hypot(csig2, salp0 * ssig2)
      cbet2 = hypotx(salp0, calp0 * csig2)
      if (cbet2 .eq. 0) then
* I.e., salp0 = 0, csig2 = 0.  Break the degeneracy in this case
        cbet2 = tiny
        csig2 = cbet2
      end if
* tan(omg2) = sin(alp0) * tan(sig2)
* No need to normalize
      somg2 = salp0 * ssig2
      comg2 = csig2
* tan(alp0) = cos(sig2)*tan(alp2)
* No need to normalize
      salp2 = salp0
      calp2 = calp0 * csig2
* omg12 = omg2 - omg1
      omg12 = atan2(somg2 * comg1 - comg2 * somg1,
     +    comg2 * comg1 + somg2 * somg1)

      lam12 = omg12 + A3c *
     +    ( sig12 + (TrgSum(.true., ssig2, csig2, C3a, nC3-1)
     +    - B31))
      lon12 = lam12 / degree
* Use Math::AngNm2 because longitude might have wrapped multiple
* times.
      lon12 = AngNm2(lon12)
      lon2 = AngNm(lon1x + lon12)
      lat2 = atan2(sbet2, f1 * cbet2) / degree
* minus signs give range [-180, 180). 0- converts -0 to +0.
      azi2 = 0 - atan2(-salp2, calp2) / degree

      if (redlp .or. scalp) then
        B22 = TrgSum(.true., ssig2, csig2, C2a, nC2)
        AB2 = (1 + A2m1) * (B22 - B21)
        J12 = (A1m1 - A2m1) * sig12 + (AB1 - AB2)
      end if
* Add parens around (csig1 * ssig2) and (ssig1 * csig2) to ensure
* accurate cancellation in the case of coincident points.
      if (redlp) m12 = b * ((dn2 * (csig1 * ssig2) -
     +    dn1 * (ssig1 * csig2)) - csig1 * csig2 * J12)
      if (scalp) then
        t = k2 * (ssig2 - ssig1) * (ssig2 + ssig1) / (dn1 + dn2)
        MM12 = csig12 + (t * ssig2 - csig2 * J12) * ssig1 / dn1
        MM21 = csig12 - (t * ssig1 - csig1 * J12) * ssig2 / dn2
      end if

      if (areap) then
        B42 = TrgSum(.false., ssig2, csig2, C4a, nC4)
        if (calp0 .eq. 0 .or. salp0 .eq. 0) then
* alp12 = alp2 - alp1, used in atan2 so no need to normalized
          salp12 = salp2 * calp1 - calp2 * salp1
          calp12 = calp2 * calp1 + salp2 * salp1
* The right thing appears to happen if alp1 = +/-180 and alp2 = 0, viz
* salp12 = -0 and alp12 = -180.  However this depends on the sign being
* attached to 0 correctly.  The following ensures the correct behavior.
          if (salp12 .eq. 0 .and. calp12 .lt. 0) then
            salp12 = tiny * calp1
            calp12 = -1
          end if
        else
* tan(alp) = tan(alp0) * sec(sig)
* tan(alp2-alp1) = (tan(alp2) -tan(alp1)) / (tan(alp2)*tan(alp1)+1)
* = calp0 * salp0 * (csig1-csig2) / (salp0^2 + calp0^2 * csig1*csig2)
* If csig12 > 0, write
*   csig1 - csig2 = ssig12 * (csig1 * ssig12 / (1 + csig12) + ssig1)
* else
*   csig1 - csig2 = csig1 * (1 - csig12) + ssig12 * ssig1
* No need to normalize
          salp12 = calp0 * salp0 *
     +        csmgt(csig1 * (1 - csig12) + ssig12 * ssig1,
     +        ssig12 * (csig1 * ssig12 / (1 + csig12) + ssig1),
     +        csig12 .le. 0)
          calp12 = salp0**2 + calp0**2 * csig1 * csig2
        end if
        SS12 = c2 * atan2(salp12, calp12) + A4 * (B42 - B41)
      end if

      if (arcp) a12s12 = csmgt(b * ((1 + A1m1) * sig12 + AB1),
     +    sig12 / degree, arcmod)

      return
      end

      subroutine invers(a, f, lat1, lon1, lat2, lon2,
     +    s12, azi1, azi2, omask, a12, m12, MM12, MM21, SS12)
* input
      double precision a, f, lat1, lon1, lat2, lon2
      integer omask
* output
      double precision s12, azi1, azi2
* optional output
      double precision a12, m12, MM12, MM21, SS12

      integer ord, nC1, nC2, nA3, nA3x, nC3, nC3x, nC4, nC4x
      parameter (ord = 6, nC1 = ord, nC2 = ord, nA3 = ord, nA3x = nA3,
     +    nC3 = ord, nC3x = (nC3 * (nC3 - 1)) / 2,
     +    nC4 = ord, nC4x = (nC4 * (nC4 + 1)) / 2)
      double precision A3x(0:nA3x-1), C3x(0:nC3x-1), C4x(0:nC4x-1),
     +    C1a(nC1), C2a(nC2), C3a(nC3-1), C4a(0:nC4-1)

      double precision csmgt, atanhx, hypotx,
     +    AngNm, AngDif, AngRnd, TrgSum, Lam12f, InvSta
      integer latsgn, lonsgn, swapp, numit
      logical arcp, redlp, scalp, areap, merid, tripn, tripb

      double precision e2, f1, ep2, n, b, c2,
     +    lat1x, lat2x, phi, salp0, calp0, k2, eps,
     +    salp1, calp1, ssig1, csig1, cbet1, sbet1, dbet1, dn1,
     +    salp2, calp2, ssig2, csig2, sbet2, cbet2, dbet2, dn2,
     +    slam12, clam12, salp12, calp12, omg12, lam12, lon12,
     +    salp1a, calp1a, salp1b, calp1b,
     +    dalp1, sdalp1, cdalp1, nsalp1, alp12, somg12, domg12,
     +    sig12, v, dv, dnm, dummy,
     +    A4, B41, B42, s12x, m12x, a12x

      double precision dblmin, dbleps, pi, degree, tiny,
     +    tol0, tol1, tol2, tolb, xthrsh
      integer digits, maxit1, maxit2
      logical init
      common /geocom/ dblmin, dbleps, pi, degree, tiny,
     +    tol0, tol1, tol2, tolb, xthrsh, digits, maxit1, maxit2, init

      if (.not.init) call geoini

      f1 = 1 - f
      e2 = f * (2 - f)
      ep2 = e2 / f1**2
      n = f / ( 2 - f)
      b = a * f1
      c2 = 0

      arcp = mod(omask/1, 2) == 1
      redlp = mod(omask/2, 2) == 1
      scalp = mod(omask/4, 2) == 1
      areap = mod(omask/8, 2) == 1

      if (areap) then
        if (e2 .eq. 0) then
          c2 = a**2
        else if (e2 .gt. 0) then
          c2 = (a**2 + b**2 * atanhx(sqrt(e2)) / sqrt(e2)) / 2
        else
          c2 = (a**2 + b**2 * atan(sqrt(abs(e2))) / sqrt(abs(e2))) / 2
        end if
      end if

      call A3cof(n, A3x)
      call C3cof(n, C3x)
      if (areap) call C4cof(n, C4x)

* Compute longitude difference (AngDiff does this carefully).  Result is
* in [-180, 180] but -180 is only for west-going geodesics.  180 is for
* east-going and meridional geodesics.
      lon12 = AngDif(AngNm(lon1), AngNm(lon2))
* If very close to being on the same half-meridian, then make it so.
      lon12 = AngRnd(lon12)
* Make longitude difference positive.
      if (lon12 .ge. 0) then
        lonsgn = 1
      else
        lonsgn = -1
      end if
      lon12 = lon12 * lonsgn
* If really close to the equator, treat as on equator.
      lat1x = AngRnd(lat1)
      lat2x = AngRnd(lat2)
* Swap points so that point with higher (abs) latitude is point 1
      if (abs(lat1x) .ge. abs(lat2x)) then
        swapp = 1
      else
        swapp = -1
      end if
      if (swapp .lt. 0) then
        lonsgn = -lonsgn
        call swap(lat1x, lat2x)
      end if
* Make lat1 <= 0
      if (lat1x .lt. 0) then
        latsgn = 1
      else
        latsgn = -1
      end if
      lat1x = lat1x * latsgn
      lat2x = lat2x * latsgn
* Now we have
*
*     0 <= lon12 <= 180
*     -90 <= lat1 <= 0
*     lat1 <= lat2 <= -lat1
*
* longsign, swapp, latsgn register the transformation to bring the
* coordinates to this canonical form.  In all cases, 1 means no change was
* made.  We make these transformations so that there are few cases to
* check, e.g., on verifying quadrants in atan2.  In addition, this
* enforces some symmetries in the results returned.

      phi = lat1x * degree
* Ensure cbet1 = +dbleps at poles
      sbet1 = f1 * sin(phi)
      cbet1 = csmgt(tiny, cos(phi), lat1x .eq. -90)
      call Norm(sbet1, cbet1)

      phi = lat2x * degree
* Ensure cbet2 = +dbleps at poles
      sbet2 = f1 * sin(phi)
      cbet2 = csmgt(tiny, cos(phi), abs(lat2x) .eq. 90)
      call Norm(sbet2, cbet2)

* If cbet1 < -sbet1, then cbet2 - cbet1 is a sensitive measure of the
* |bet1| - |bet2|.  Alternatively (cbet1 >= -sbet1), abs(sbet2) + sbet1 is
* a better measure.  This logic is used in assigning calp2 in Lambda12.
* Sometimes these quantities vanish and in that case we force bet2 = +/-
* bet1 exactly.  An example where is is necessary is the inverse problem
* 48.522876735459 0 -48.52287673545898293 179.599720456223079643
* which failed with Visual Studio 10 (Release and Debug)

      if (cbet1 .lt. -sbet1) then
        if (cbet2 .eq. cbet1) sbet2 = sign(sbet1, sbet2)
      else
        if (abs(sbet2) .eq. -sbet1) cbet2 = cbet1
      end if

      dn1 = sqrt(1 + ep2 * sbet1**2)
      dn2 = sqrt(1 + ep2 * sbet2**2)

      lam12 = lon12 * degree
      slam12 = sin(lam12)
      if (lon12 .eq. 180) slam12 = 0
* lon12 == 90 isn't interesting
      clam12 = cos(lam12)

* Suppress bogus warnings about unitialized variables
      a12x = 0
      merid = lat1x .eq. -90 .or. slam12 == 0

      if (merid) then

* Endpoints are on a single full meridian, so the geodesic might lie on
* a meridian.

* Head to the target longitude
        calp1 = clam12
        salp1 = slam12
* At the target we're heading north
        calp2 = 1
        salp2 = 0

* tan(bet) = tan(sig) * cos(alp)
        ssig1 = sbet1
        csig1 = calp1 * cbet1
        ssig2 = sbet2
        csig2 = calp2 * cbet2

* sig12 = sig2 - sig1
        sig12 = atan2(max(csig1 * ssig2 - ssig1 * csig2, 0d0),
     +      csig1 * csig2 + ssig1 * ssig2)
        call Lengs(n, sig12, ssig1, csig1, dn1, ssig2, csig2, dn2,
     +      cbet1, cbet2, s12x, m12x, dummy,
     +      scalp, MM12, MM21, ep2, C1a, C2a)

* Add the check for sig12 since zero length geodesics might yield m12 <
* 0.  Test case was
*
*    echo 20.001 0 20.001 0 | Geod -i
*
* In fact, we will have sig12 > pi/2 for meridional geodesic which is
* not a shortest path.
        if (sig12 .lt. 1 .or. m12x .ge. 0) then
          m12x = m12x * b
          s12x = s12x * b
          a12x = sig12 / degree
        else
* m12 < 0, i.e., prolate and too close to anti-podal
          merid = .false.
        end if
      end if

* Mimic the way Lambda12 works with calp1 = 0
      if (.not. merid .and. sbet1 .eq. 0 .and.
     +    (f .le. 0 .or. lam12 .le. pi - f * pi)) then

* Geodesic runs along equator
        calp1 = 0
        calp2 = 0
        salp1 = 1
        salp2 = 1
        s12x = a * lam12
        sig12 = lam12 / f1
        omg12 = sig12
        m12x = b * sin(sig12)
        if (scalp) then
          MM12 = cos(sig12)
          MM21 = MM12
        end if
        a12x = lon12 / f1
      else if (.not. merid) then
* Now point1 and point2 belong within a hemisphere bounded by a
* meridian and geodesic is neither meridional or equatorial.

* Figure a starting point for Newton's method
        sig12 = InvSta(sbet1, cbet1, dn1, sbet2, cbet2, dn2, lam12,
     +      f, A3x, salp1, calp1, salp2, calp2, C1a, C2a)

        if (sig12 .ge. 0) then
* Short lines (InvSta sets salp2, calp2)
          dnm = (dn1 + dn2) / 2
          s12x = sig12 * b * dnm
          m12x = dnm**2 * b * sin(sig12 / dnm)
          if (scalp) then
            MM12 = cos(sig12 / dnm)
            MM21 = MM12
          end if
          a12x = sig12 / degree
          omg12 = lam12 / (f1 * dnm)
        else

* Newton's method.  This is a straightforward solution of f(alp1) =
* lambda12(alp1) - lam12 = 0 with one wrinkle.  f(alp) has exactly one
* root in the interval (0, pi) and its derivative is positive at the
* root.  Thus f(alp) is positive for alp > alp1 and negative for alp <
* alp1.  During the course of the iteration, a range (alp1a, alp1b) is
* maintained which brackets the root and with each evaluation of
* f(alp) the range is shrunk, if possible.  Newton's method is
* restarted whenever the derivative of f is negative (because the new
* value of alp1 is then further from the solution) or if the new
* estimate of alp1 lies outside (0,pi); in this case, the new starting
* guess is taken to be (alp1a + alp1b) / 2.

* Bracketing range
          salp1a = tiny
          calp1a = 1
          salp1b = tiny
          calp1b = -1
          tripn = .false.
          tripb = .false.
          do 10 numit = 0, maxit2-1
* the WGS84 test set: mean = 1.47, sd = 1.25, max = 16
* WGS84 and random input: mean = 2.85, sd = 0.60
            v = Lam12f(sbet1, cbet1, dn1, sbet2, cbet2, dn2,
     +          salp1, calp1, f, A3x, C3x, salp2, calp2, sig12,
     +          ssig1, csig1, ssig2, csig2,
     +          eps, omg12, numit .lt. maxit1, dv,
     +          C1a, C2a, C3a) - lam12
* 2 * tol0 is approximately 1 ulp for a number in [0, pi].
* Reversed test to allow escape with NaNs
            if (tripb .or.
     +          .not. (abs(v) .ge. csmgt(8d0, 2d0, tripn) * tol0))
     +          go to 20
* Update bracketing values
            if (v .gt. 0 .and. (numit .gt. maxit1 .or.
     +          calp1/salp1 .gt. calp1b/salp1b)) then
              salp1b = salp1
              calp1b = calp1
            else if (numit .gt. maxit1 .or.
     +            calp1/salp1 .lt. calp1a/salp1a) then
              salp1a = salp1
              calp1a = calp1
            end if
            if (numit .lt. maxit1 .and. dv .gt. 0) then
              dalp1 = -v/dv
              sdalp1 = sin(dalp1)
              cdalp1 = cos(dalp1)
              nsalp1 = salp1 * cdalp1 + calp1 * sdalp1
              if (nsalp1 .gt. 0 .and. abs(dalp1) .lt. pi) then
                calp1 = calp1 * cdalp1 - salp1 * sdalp1
                salp1 = nsalp1
                call Norm(salp1, calp1)
* In some regimes we don't get quadratic convergence because
* slope -> 0.  So use convergence conditions based on dbleps
* instead of sqrt(dbleps).
                tripn = abs(v) .le. 16 * tol0
                go to 10
              end if
            end if
* Either dv was not postive or updated value was outside legal
* range.  Use the midpoint of the bracket as the next estimate.
* This mechanism is not needed for the WGS84 ellipsoid, but it does
* catch problems with more eccentric ellipsoids.  Its efficacy is
* such for the WGS84 test set with the starting guess set to alp1 =
* 90deg:
* the WGS84 test set: mean = 5.21, sd = 3.93, max = 24
* WGS84 and random input: mean = 4.74, sd = 0.99
            salp1 = (salp1a + salp1b)/2
            calp1 = (calp1a + calp1b)/2
            call Norm(salp1, calp1)
            tripn = .false.
            tripb = abs(salp1a - salp1) + (calp1a - calp1) .lt. tolb
     +          .or. abs(salp1 - salp1b) + (calp1 - calp1b) .lt. tolb
 10       continue
 20       continue
          call Lengs(eps, sig12, ssig1, csig1, dn1,
     +        ssig2, csig2, dn2, cbet1, cbet2, s12x, m12x, dummy,
     +        scalp, MM12, MM21, ep2, C1a, C2a)
          m12x = m12x * b
          s12x = s12x * b
          a12x = sig12 / degree
          omg12 = lam12 - omg12
        end if
      end if

* Convert -0 to 0
      s12 = 0 + s12x
      if (redlp) m12 = 0 + m12x

      if (areap) then
* From Lambda12: sin(alp1) * cos(bet1) = sin(alp0)
        salp0 = salp1 * cbet1
        calp0 = hypotx(calp1, salp1 * sbet1)
        if (calp0 .ne. 0 .and. salp0 .ne. 0) then
* From Lambda12: tan(bet) = tan(sig) * cos(alp)
          ssig1 = sbet1
          csig1 = calp1 * cbet1
          ssig2 = sbet2
          csig2 = calp2 * cbet2
          k2 = calp0**2 * ep2
          eps = k2 / (2 * (1 + sqrt(1 + k2)) + k2)
* Multiplier = a^2 * e^2 * cos(alpha0) * sin(alpha0).
          A4 = a**2 * calp0 * salp0 * e2
          call Norm(ssig1, csig1)
          call Norm(ssig2, csig2)
          call C4f(eps, C4x, C4a)
          B41 = TrgSum(.false., ssig1, csig1, C4a, nC4)
          B42 = TrgSum(.false., ssig2, csig2, C4a, nC4)
          SS12 = A4 * (B42 - B41)
        else
* Avoid problems with indeterminate sig1, sig2 on equator
          SS12 = 0
        end if

        if (.not. merid .and. omg12 .lt. 0.75d0 * pi
     +      .and. sbet2 - sbet1 .lt. 1.75d0) then
* Use tan(Gamma/2) = tan(omg12/2)
* * (tan(bet1/2)+tan(bet2/2))/(1+tan(bet1/2)*tan(bet2/2))
* with tan(x/2) = sin(x)/(1+cos(x))
          somg12 = sin(omg12)
          domg12 = 1 + cos(omg12)
          dbet1 = 1 + cbet1
          dbet2 = 1 + cbet2
          alp12 = 2 * atan2(somg12 * (sbet1 * dbet2 + sbet2 * dbet1),
     +        domg12 * ( sbet1 * sbet2 + dbet1 * dbet2 ) )
        else
* alp12 = alp2 - alp1, used in atan2 so no need to normalize
          salp12 = salp2 * calp1 - calp2 * salp1
          calp12 = calp2 * calp1 + salp2 * salp1
* The right thing appears to happen if alp1 = +/-180 and alp2 = 0, viz
* salp12 = -0 and alp12 = -180.  However this depends on the sign
* being attached to 0 correctly.  The following ensures the correct
* behavior.
          if (salp12 .eq. 0 .and. calp12 .lt. 0) then
            salp12 = tiny * calp1
            calp12 = -1
          end if
          alp12 = atan2(salp12, calp12)
        end if
        SS12 = SS12 + c2 * alp12
        SS12 = SS12 * swapp * lonsgn * latsgn
* Convert -0 to 0
        SS12 = 0 + SS12
      end if

* Convert calp, salp to azimuth accounting for lonsgn, swapp, latsgn.
      if (swapp .lt. 0) then
        call swap(salp1, salp2)
        call swap(calp1, calp2)
        if (scalp) call swap(MM12, MM21)
      end if

      salp1 = salp1 * swapp * lonsgn
      calp1 = calp1 * swapp * latsgn
      salp2 = salp2 * swapp * lonsgn
      calp2 = calp2 * swapp * latsgn

* minus signs give range [-180, 180). 0- converts -0 to +0.
      azi1 = 0 - atan2(-salp1, calp1) / degree
      azi2 = 0 - atan2(-salp2, calp2) / degree

      if (arcp) a12 = a12x

      return
      end

      subroutine area(a, f, lats, lons, n, S, P)
* input
      integer n
      double precision a, f, lats(0:n-1), lons(0:n-1)
* output
      double precision S, P

      integer i, omask, cross, trnsit
      double precision s12, azi1, azi2, dummy, SS12, b, e2, c2, area0,
     +    atanhx

      double precision dblmin, dbleps, pi, degree, tiny,
     +    tol0, tol1, tol2, tolb, xthrsh
      integer digits, maxit1, maxit2
      logical init
      common /geocom/ dblmin, dbleps, pi, degree, tiny,
     +    tol0, tol1, tol2, tolb, xthrsh, digits, maxit1, maxit2, init

      omask = 8
      S = 0
      P = 0
      cross = 0
      do 10 i = 0, n-1
        call invers(a, f, lats(i), lons(i),
     +      lats(mod(i+1, n)), lons(mod(i+1, n)),
     +      s12, azi1, azi2, omask, dummy, dummy, dummy, dummy, SS12)
        P = P + s12
        S = S - SS12
        cross = cross + trnsit(lons(i), lons(mod(i+1, n)))
 10   continue
      b = a * (1 - f)
      e2 = f * (2 - f)
      if (e2 .eq. 0) then
        c2 = a**2
      else if (e2 .gt. 0) then
        c2 = (a**2 + b**2 * atanhx(sqrt(e2)) / sqrt(e2)) / 2
      else
        c2 = (a**2 + b**2 * atan(sqrt(abs(e2))) / sqrt(abs(e2))) / 2
      end if
      area0 = 4 * pi * c2
      if (mod(abs(cross), 2) .eq. 1) then
        if (S .lt. 0) then
          S = S + area0/2
        else
          S = S - area0/2
        end if
      end if
      if (S .gt. area0/2) then
        S = S - area0
      else if (S .le. -area0/2) then
        S = S + area0
      end if

      return
      end

      subroutine Lengs(eps, sig12,
     +    ssig1, csig1, dn1, ssig2, csig2, dn2,
     +    cbet1, cbet2, s12b, m12b, m0,
     +    scalp, MM12, MM21, ep2, C1a, C2a)
* input
      double precision eps, sig12, ssig1, csig1, dn1, ssig2, csig2, dn2,
     +    cbet1, cbet2, ep2
      logical scalp
* output
      double precision s12b, m12b, m0
* optional output
      double precision MM12, MM21
* temporary storage
      double precision C1a(*), C2a(*)

      integer ord, nC1, nC2
      parameter (ord = 6, nC1 = ord, nC2 = ord)

      double precision A1m1f, A2m1f, TrgSum
      double precision A1m1, AB1, A2m1, AB2, J12, csig12, t

* Return m12b = (reduced length)/b; also calculate s12b = distance/b,
* and m0 = coefficient of secular term in expression for reduced length.
      call C1f(eps, C1a)
      call C2f(eps, C2a)

      A1m1 = A1m1f(eps)
      AB1 = (1 + A1m1) * (TrgSum(.true., ssig2, csig2, C1a, nC1) -
     +    TrgSum(.true., ssig1, csig1, C1a, nC1))
      A2m1 = A2m1f(eps)
      AB2 = (1 + A2m1) * (TrgSum(.true., ssig2, csig2, C2a, nC2) -
     +    TrgSum(.true., ssig1, csig1, C2a, nC2))
      m0 = A1m1 - A2m1
      J12 = m0 * sig12 + (AB1 - AB2)
* Missing a factor of b.
* Add parens around (csig1 * ssig2) and (ssig1 * csig2) to ensure accurate
* cancellation in the case of coincident points.
      m12b = dn2 * (csig1 * ssig2) - dn1 * (ssig1 * csig2) -
     +    csig1 * csig2 * J12
* Missing a factor of b
      s12b = (1 + A1m1) * sig12 + AB1
      if (scalp) then
        csig12 = csig1 * csig2 + ssig1 * ssig2
        t = ep2 * (cbet1 - cbet2) * (cbet1 + cbet2) / (dn1 + dn2)
        MM12 = csig12 + (t * ssig2 - csig2 * J12) * ssig1 / dn1
        MM21 = csig12 - (t * ssig1 - csig1 * J12) * ssig2 / dn2
      end if

      return
      end

      double precision function Astrd(x, y)
* Solve k^4+2*k^3-(x^2+y^2-1)*k^2-2*y^2*k-y^2 = 0 for positive root k.
* This solution is adapted from Geocentric::Reverse.
* input
      double precision x, y

      double precision cbrt, csmgt
      double precision k, p, q, r, S, r2, r3, disc, u,
     +    T3, T, ang, v, uv, w

      p = x**2
      q = y**2
      r = (p + q - 1) / 6
      if ( .not. (q .eq. 0 .and. r .lt. 0) ) then
* Avoid possible division by zero when r = 0 by multiplying equations
* for s and t by r^3 and r, resp.
* S = r^3 * s
        S = p * q / 4
        r2 = r**2
        r3 = r * r2
* The discrimant of the quadratic equation for T3.  This is zero on
* the evolute curve p^(1/3)+q^(1/3) = 1
        disc = S * (S + 2 * r3)
        u = r
        if (disc .ge. 0) then
          T3 = S + r3
* Pick the sign on the sqrt to maximize abs(T3).  This minimizes loss
* of precision due to cancellation.  The result is unchanged because
* of the way the T is used in definition of u.
* T3 = (r * t)^3
          T3 = T3 + csmgt(-sqrt(disc), sqrt(disc), T3 .lt. 0)
* N.B. cbrt always returns the real root.  cbrt(-8) = -2.
* T = r * t
          T = cbrt(T3)
* T can be zero; but then r2 / T -> 0.
          if (T .ne. 0) u = u + T + r2 / T
        else
* T is complex, but the way u is defined the result is real.
          ang = atan2(sqrt(-disc), -(S + r3))
* There are three possible cube roots.  We choose the root which
* avoids cancellation.  Note that disc < 0 implies that r < 0.
          u = u + 2 * r * cos(ang / 3)
        end if
* guaranteed positive
        v = sqrt(u**2 + q)
* Avoid loss of accuracy when u < 0.
* u+v, guaranteed positive
        uv = csmgt(q / (v - u), u + v, u .lt. 0)
* positive?
        w = (uv - q) / (2 * v)
* Rearrange expression for k to avoid loss of accuracy due to
* subtraction.  Division by 0 not possible because uv > 0, w >= 0.
* guaranteed positive
        k = uv / (sqrt(uv + w**2) + w)
      else
* q == 0 && r <= 0
* y = 0 with |x| <= 1.  Handle this case directly.
* for y small, positive root is k = abs(y)/sqrt(1-x^2)
        k = 0
      end if
      Astrd = k

      return
      end

      double precision function InvSta(sbet1, cbet1, dn1,
     +    sbet2, cbet2, dn2, lam12, f, A3x,
     +    salp1, calp1, salp2, calp2,
     +    C1a, C2a)
* Return a starting point for Newton's method in salp1 and calp1 (function
* value is -1).  If Newton's method doesn't need to be used, return also
* salp2 and calp2 and function value is sig12.
* input
      double precision sbet1, cbet1, dn1, sbet2, cbet2, dn2, lam12,
     +    f, A3x(*)
* output
      double precision salp1, calp1, salp2, calp2
* temporary
      double precision C1a(*), C2a(*)

      double precision csmgt, hypotx, A3f, Astrd
      logical shortp
      double precision f1, e2, ep2, n, etol2, k2, eps, sig12,
     +    sbet12, cbet12, sbt12a, omg12, somg12, comg12, ssig12, csig12,
     +    x, y, lamscl, betscl, cbt12a, bt12a, m12b, m0, dummy,
     +    k, omg12a

      double precision dblmin, dbleps, pi, degree, tiny,
     +    tol0, tol1, tol2, tolb, xthrsh
      integer digits, maxit1, maxit2
      logical init
      common /geocom/ dblmin, dbleps, pi, degree, tiny,
     +    tol0, tol1, tol2, tolb, xthrsh, digits, maxit1, maxit2, init

      f1 = 1 - f
      e2 = f * (2 - f)
      ep2 = e2 / (1 - e2)
      n = f / (2 - f)
      etol2 = 0.01d0 * tol2 / max(0.1d0, sqrt(abs(e2)))

* Return value
      sig12 = -1
* bet12 = bet2 - bet1 in [0, pi); bt12a = bet2 + bet1 in (-pi, 0]
      sbet12 = sbet2 * cbet1 - cbet2 * sbet1
      cbet12 = cbet2 * cbet1 + sbet2 * sbet1
      sbt12a = sbet2 * cbet1 + cbet2 * sbet1

      shortp = cbet12 .ge. 0 .and. sbet12 .lt. 0.5d0 .and.
     +    lam12 .le. pi / 6

      omg12 = lam12
      if (shortp) omg12 = omg12 / (f1 * (dn1 + dn2) / 2)
      somg12 = sin(omg12)
      comg12 = cos(omg12)

      salp1 = cbet2 * somg12
      calp1 = csmgt(sbet12 + cbet2 * sbet1 * somg12**2 / (1 + comg12),
     +    sbt12a - cbet2 * sbet1 * somg12**2 / (1 - comg12),
     +    comg12 .ge. 0)

      ssig12 = hypotx(salp1, calp1)
      csig12 = sbet1 * sbet2 + cbet1 * cbet2 * comg12

      if (shortp .and. ssig12 .lt. etol2) then
* really short lines
        salp2 = cbet1 * somg12
        calp2 = sbet12 - cbet1 * sbet2 * somg12**2 / (1 + comg12)
        call Norm(salp2, calp2)
* Set return value
        sig12 = atan2(ssig12, csig12)
      else if (abs(n) .gt. 0.1d0 .or. csig12 .ge. 0 .or.
     +      ssig12 .ge. 6 * abs(n) * pi * cbet1**2) then
* Nothing to do, zeroth order spherical approximation is OK
        continue
      else
* Scale lam12 and bet2 to x, y coordinate system where antipodal point
* is at origin and singular point is at y = 0, x = -1.
        if (f .ge. 0) then
* x = dlong, y = dlat
          k2 = sbet1**2 * ep2
          eps = k2 / (2 * (1 + sqrt(1 + k2)) + k2)
          lamscl = f * cbet1 * A3f(eps, A3x) * pi
          betscl = lamscl * cbet1
          x = (lam12 - pi) / lamscl
          y = sbt12a / betscl
        else
* f < 0: x = dlat, y = dlong
          cbt12a = cbet2 * cbet1 - sbet2 * sbet1
          bt12a = atan2(sbt12a, cbt12a)
* In the case of lon12 = 180, this repeats a calculation made in
* Inverse.
          call Lengs(n, pi + bt12a,
     +        sbet1, -cbet1, dn1, sbet2, cbet2, dn2,
     +        cbet1, cbet2, dummy, m12b, m0, .false.,
     +        dummy, dummy, ep2, C1a, C2a)
          x = -1 + m12b / (cbet1 * cbet2 * m0 * pi)
          betscl = csmgt(sbt12a / x, -f * cbet1**2 * pi,
     +        x .lt. -0.01d0)
          lamscl = betscl / cbet1
          y = (lam12 - pi) / lamscl
        end if

        if (y .gt. -tol1 .and. x .gt. -1 - xthrsh) then
* strip near cut
          if (f .ge. 0) then
            salp1 = min(1d0, -x)
            calp1 = - sqrt(1 - salp1**2)
          else
            calp1 = max(csmgt(0d0, 1d0, x .gt. -tol1), x)
            salp1 = sqrt(1 - calp1**2)
          end if
        else
* Estimate alp1, by solving the astroid problem.
*
* Could estimate alpha1 = theta + pi/2, directly, i.e.,
*   calp1 = y/k; salp1 = -x/(1+k);  for f >= 0
*   calp1 = x/(1+k); salp1 = -y/k;  for f < 0 (need to check)
*
* However, it's better to estimate omg12 from astroid and use
* spherical formula to compute alp1.  This reduces the mean number of
* Newton iterations for astroid cases from 2.24 (min 0, max 6) to 2.12
* (min 0 max 5).  The changes in the number of iterations are as
* follows:
*
* change percent
*    1       5
*    0      78
*   -1      16
*   -2       0.6
*   -3       0.04
*   -4       0.002
*
* The histogram of iterations is (m = number of iterations estimating
* alp1 directly, n = number of iterations estimating via omg12, total
* number of trials = 148605):
*
*  iter    m      n
*    0   148    186
*    1 13046  13845
*    2 93315 102225
*    3 36189  32341
*    4  5396      7
*    5   455      1
*    6    56      0
*
* Because omg12 is near pi, estimate work with omg12a = pi - omg12
          k = Astrd(x, y)
          omg12a = lamscl *
     +        csmgt(-x * k/(1 + k), -y * (1 + k)/k, f .ge. 0)
          somg12 = sin(omg12a)
          comg12 = -cos(omg12a)
* Update spherical estimate of alp1 using omg12 instead of lam12
          salp1 = cbet2 * somg12
          calp1 = sbt12a - cbet2 * sbet1 * somg12**2 / (1 - comg12)
        end if
      end if
* Sanity check on starting guess
      if (salp1 .gt. 0) then
        call Norm(salp1, calp1)
      else
        salp1 = 1
        calp1 = 0
      end if
      InvSta = sig12

      return
      end

      double precision function Lam12f(sbet1, cbet1, dn1,
     +    sbet2, cbet2, dn2, salp1, calp1, f, A3x, C3x, salp2, calp2,
     +    sig12, ssig1, csig1, ssig2, csig2, eps, domg12, diffp, dlam12,
     +    C1a, C2a, C3a)
* input
      double precision sbet1, cbet1, dn1, sbet2, cbet2, dn2,
     +    salp1, calp1, f, A3x(*), C3x(*)
      logical diffp
* output
      double precision salp2, calp2, sig12, ssig1, csig1, ssig2, csig2,
     +    eps, domg12
* optional output
      double precision dlam12
* temporary
      double precision C1a(*), C2a(*), C3a(*)

      integer ord, nC3
      parameter (ord = 6, nC3 = ord)

      double precision csmgt, hypotx, A3f, TrgSum

      double precision f1, e2, ep2, salp0, calp0,
     +    somg1, comg1, somg2, comg2, omg12, lam12, B312, h0, k2, dummy

      double precision dblmin, dbleps, pi, degree, tiny,
     +    tol0, tol1, tol2, tolb, xthrsh
      integer digits, maxit1, maxit2
      logical init
      common /geocom/ dblmin, dbleps, pi, degree, tiny,
     +    tol0, tol1, tol2, tolb, xthrsh, digits, maxit1, maxit2, init

      f1 = 1 - f
      e2 = f * (2 - f)
      ep2 = e2 / (1 - e2)
* Break degeneracy of equatorial line.  This case has already been
* handled.
      if (sbet1 .eq. 0 .and. calp1 .eq. 0) calp1 = -tiny

* sin(alp1) * cos(bet1) = sin(alp0)
      salp0 = salp1 * cbet1
* calp0 > 0
      calp0 = hypotx(calp1, salp1 * sbet1)

* tan(bet1) = tan(sig1) * cos(alp1)
* tan(omg1) = sin(alp0) * tan(sig1) = tan(omg1)=tan(alp1)*sin(bet1)
      ssig1 = sbet1
      somg1 = salp0 * sbet1
      csig1 = calp1 * cbet1
      comg1 = csig1
      call Norm(ssig1, csig1)
* Norm(somg1, comg1); -- don't need to normalize!

* Enforce symmetries in the case abs(bet2) = -bet1.  Need to be careful
* about this case, since this can yield singularities in the Newton
* iteration.
* sin(alp2) * cos(bet2) = sin(alp0)
      salp2 = csmgt(salp0 / cbet2, salp1, cbet2 .ne. cbet1)
* calp2 = sqrt(1 - sq(salp2))
*       = sqrt(sq(calp0) - sq(sbet2)) / cbet2
* and subst for calp0 and rearrange to give (choose positive sqrt
* to give alp2 in [0, pi/2]).
      calp2 = csmgt(sqrt((calp1 * cbet1)**2 +
     +    csmgt((cbet2 - cbet1) * (cbet1 + cbet2),
     +    (sbet1 - sbet2) * (sbet1 + sbet2),
     +    cbet1 .lt. -sbet1)) / cbet2,
     +    abs(calp1), cbet2 .ne. cbet1 .or. abs(sbet2) .ne. -sbet1)
* tan(bet2) = tan(sig2) * cos(alp2)
* tan(omg2) = sin(alp0) * tan(sig2).
      ssig2 = sbet2
      somg2 = salp0 * sbet2
      csig2 = calp2 * cbet2
      comg2 = csig2
      call Norm(ssig2, csig2)
* Norm(somg2, comg2); -- don't need to normalize!

* sig12 = sig2 - sig1, limit to [0, pi]
      sig12 = atan2(max(csig1 * ssig2 - ssig1 * csig2, 0d0),
     +    csig1 * csig2 + ssig1 * ssig2)

* omg12 = omg2 - omg1, limit to [0, pi]
      omg12 = atan2(max(comg1 * somg2 - somg1 * comg2, 0d0),
     +    comg1 * comg2 + somg1 * somg2)
      k2 = calp0**2 * ep2
      eps = k2 / (2 * (1 + sqrt(1 + k2)) + k2)
      call C3f(eps, C3x, C3a)
      B312 = (TrgSum(.true., ssig2, csig2, C3a, nC3-1) -
     +    TrgSum(.true., ssig1, csig1, C3a, nC3-1))
      h0 = -f * A3f(eps, A3x)
      domg12 = salp0 * h0 * (sig12 + B312)
      lam12 = omg12 + domg12

      if (diffp) then
        if (calp2 .eq. 0) then
          dlam12 = - 2 * f1 * dn1 / sbet1
        else
          call Lengs(eps, sig12, ssig1, csig1, dn1, ssig2, csig2, dn2,
     +        cbet1, cbet2, dummy, dlam12, dummy,
     +        .false., dummy, dummy, ep2, C1a, C2a)
          dlam12 = dlam12 * f1 / (calp2 * cbet2)
        end if
      end if
      Lam12f = lam12

      return
      end

      double precision function A3f(eps, A3x)
* Evaluate sum(A3x[k] * eps^k, k, 0, nA3x-1) by Horner's method
      integer ord, nA3, nA3x
      parameter (ord = 6, nA3 = ord, nA3x = nA3)

* input
      double precision eps
* output
      double precision A3x(0: nA3x-1)

      integer i
      A3f = 0
      do 10 i = nA3x-1, 0, -1
        A3f = eps * A3f + A3x(i)
 10   continue
      return
      end

      subroutine C3f(eps, C3x, c)
* Evaluate C3 coeffs by Horner's method
* Elements c[1] thru c[nC3-1] are set
      integer ord, nC3, nC3x
      parameter (ord = 6, nC3 = ord, nC3x = (nC3 * (nC3 - 1)) / 2)

* input
      double precision eps, C3x(0:nC3x-1)
* output
      double precision c(nC3-1)

      integer i, j, k
      double precision t, mult

      j = nC3x
      do 20 k = nC3-1, 1 , -1
        t = 0
        do 10 i = nC3 - k, 1, -1
          j = j - 1
          t = eps * t + C3x(j)
 10     continue
        c(k) = t
 20   continue

      mult = 1
      do 30 k = 1, nC3-1
        mult = mult * eps
        c(k) = c(k) * mult
 30   continue

      return
      end

      subroutine C4f(eps, C4x, c)
* Evaluate C4 coeffs by Horner's method
* Elements c[0] thru c[nC4-1] are set
      integer ord, nC4, nC4x
      parameter (ord = 6, nC4 = ord, nC4x = (nC4 * (nC4 + 1)) / 2)

* input
      double precision eps, C4x(0:nC4x-1)
*output
      double precision c(0:nC4-1)

      integer i, j, k
      double precision t, mult

      j = nC4x
      do 20 k = nC4-1, 0, -1
         t = 0
         do 10 i = nC4 - k, 1, -1
            j = j - 1
            t = eps * t + C4x(j)
 10      continue
         c(k) = t
 20   continue

      mult = 1
      do 30 k = 1, nC4-1
         mult = mult * eps
         c(k) = c(k) * mult
 30   continue

      return
      end

* Generated by Maxima on 2010-09-04 10:26:17-04:00

      double precision function A1m1f(eps)
* The scale factor A1-1 = mean value of (d/dsigma)I1 - 1
* input
      double precision eps

      double precision eps2, t

      eps2 = eps**2
      t = eps2*(eps2*(eps2+4)+64)/256
      A1m1f = (t + eps) / (1 - eps)
      return
      end

      subroutine C1f(eps, c)
* The coefficients C1[l] in the Fourier expansion of B1
      integer ord, nC1
      parameter (ord = 6, nC1 = ord)

* input
      double precision eps
* output
      double precision c(nC1)

      double precision eps2, d

      eps2 = eps**2
      d = eps
      c(1) = d*((6-eps2)*eps2-16)/32
      d = d * eps
      c(2) = d*((64-9*eps2)*eps2-128)/2048
      d = d * eps
      c(3) = d*(9*eps2-16)/768
      d = d * eps
      c(4) = d*(3*eps2-5)/512
      d = d * eps
      c(5) = -7*d/1280
      d = d * eps
      c(6) = -7*d/2048

      return
      end

      subroutine C1pf(eps, c)
* The coefficients C1p[l] in the Fourier expansion of B1p
      integer ord, nC1p
      parameter (ord = 6, nC1p = ord)

* input
      double precision eps
* output
      double precision c(nC1p)

      double precision eps2, d

      eps2 = eps**2
      d = eps
      c(1) = d*(eps2*(205*eps2-432)+768)/1536
      d = d * eps
      c(2) = d*(eps2*(4005*eps2-4736)+3840)/12288
      d = d * eps
      c(3) = d*(116-225*eps2)/384
      d = d * eps
      c(4) = d*(2695-7173*eps2)/7680
      d = d * eps
      c(5) = 3467*d/7680
      d = d * eps
      c(6) = 38081*d/61440

      return
      end

* The scale factor A2-1 = mean value of (d/dsigma)I2 - 1
      double precision function A2m1f(eps)
* input
      double precision eps

      double precision eps2, t

      eps2 = eps**2
      t = eps2*(eps2*(25*eps2+36)+64)/256
      A2m1f = t * (1 - eps) - eps

      return
      end

      subroutine C2f(eps, c)
* The coefficients C2[l] in the Fourier expansion of B2
      integer ord, nC2
      parameter (ord = 6, nC2 = ord)

* input
      double precision eps
* output
      double precision c(nC2)

      double precision eps2, d

      eps2 = eps**2
      d = eps
      c(1) = d*(eps2*(eps2+2)+16)/32
      d = d * eps
      c(2) = d*(eps2*(35*eps2+64)+384)/2048
      d = d * eps
      c(3) = d*(15*eps2+80)/768
      d = d * eps
      c(4) = d*(7*eps2+35)/512
      d = d * eps
      c(5) = 63*d/1280
      d = d * eps
      c(6) = 77*d/2048

      return
      end

      subroutine A3cof(n, A3x)
* The scale factor A3 = mean value of (d/dsigma)I3
      integer ord, nA3, nA3x
      parameter (ord = 6, nA3 = ord, nA3x = nA3)

* input
      double precision n
* output
      double precision A3x(0:nA3x-1)

      A3x(0) = 1
      A3x(1) = (n-1)/2
      A3x(2) = (n*(3*n-1)-2)/8
      A3x(3) = ((-n-3)*n-1)/16
      A3x(4) = (-2*n-3)/64
      A3x(5) = -3/128d0

      return
      end

      subroutine C3cof(n, C3x)
* The coefficients C3[l] in the Fourier expansion of B3
      integer ord, nC3, nC3x
      parameter (ord = 6, nC3 = ord, nC3x = (nC3 * (nC3 - 1)) / 2)

* input
      double precision n
* output
      double precision C3x(0:nC3x-1)

      C3x(0) = (1-n)/4
      C3x(1) = (1-n*n)/8
      C3x(2) = ((3-n)*n+3)/64
      C3x(3) = (2*n+5)/128
      C3x(4) = 3/128d0
      C3x(5) = ((n-3)*n+2)/32
      C3x(6) = ((-3*n-2)*n+3)/64
      C3x(7) = (n+3)/128
      C3x(8) = 5/256d0
      C3x(9) = (n*(5*n-9)+5)/192
      C3x(10) = (9-10*n)/384
      C3x(11) = 7/512d0
      C3x(12) = (7-14*n)/512
      C3x(13) = 7/512d0
      C3x(14) = 21/2560d0

      return
      end

* Generated by Maxima on 2012-10-19 08:02:34-04:00

      subroutine C4cof(n, C4x)
* The coefficients C4[l] in the Fourier expansion of I4
      integer ord, nC4, nC4x
      parameter (ord = 6, nC4 = ord, nC4x = (nC4 * (nC4 + 1)) / 2)

* input
      double precision n
* output
      double precision C4x(0:nC4x-1)

      C4x(0) = (n*(n*(n*(n*(100*n+208)+572)+3432)-12012)+30030)/45045
      C4x(1) = (n*(n*(n*(64*n+624)-4576)+6864)-3003)/15015
      C4x(2) = (n*((14144-10656*n)*n-4576)-858)/45045
      C4x(3) = ((-224*n-4784)*n+1573)/45045
      C4x(4) = (1088*n+156)/45045
      C4x(5) = 97/15015d0
      C4x(6) = (n*(n*((-64*n-624)*n+4576)-6864)+3003)/135135
      C4x(7) = (n*(n*(5952*n-11648)+9152)-2574)/135135
      C4x(8) = (n*(5792*n+1040)-1287)/135135
      C4x(9) = (468-2944*n)/135135
      C4x(10) = 1/9009d0
      C4x(11) = (n*((4160-1440*n)*n-4576)+1716)/225225
      C4x(12) = ((4992-8448*n)*n-1144)/225225
      C4x(13) = (1856*n-936)/225225
      C4x(14) = 8/10725d0
      C4x(15) = (n*(3584*n-3328)+1144)/315315
      C4x(16) = (1024*n-208)/105105
      C4x(17) = -136/63063d0
      C4x(18) = (832-2560*n)/405405
      C4x(19) = -128/135135d0
      C4x(20) = 128/99099d0

      return
      end

      double precision function sumx(u, v, t)
* input
      double precision u, v
* output
      double precision t

      double precision up, vpp
      sumx = u + v
      up = sumx - v
      vpp = sumx - up
      up = up - u
      vpp = vpp -  v
      t = -(up + vpp)

      return
      end

      double precision function AngNm(x)
* input
      double precision x

      if (x .ge. 180) then
         x = x - 360
      else if (x .lt. -180) then
         x = x + 360
      end if
      AngNm = x
      return
      end

      double precision function AngNm2(x)
* input
      double precision x

      double precision AngNm
      x = mod(x, 360d0)
      AngNm2 = AngNm(x)
      return
      end

      double precision function AngDif(x, y)
* input
      double precision x, y

      double precision d, t, sumx
      d = sumx(-x, y, t)
      if ((d - 180d0) + t .gt. 0d0) then
        d = d - 360d0
      else if ((d + 180d0) + t .le. 0d0) then
        d = d + 360d0
      end if
      AngDif = d + t
      end

      double precision function AngRnd(x)
* The makes the smallest gap in x = 1/16 - nextafter(1/16, 0) = 1/2^57
* for reals = 0.7 pm on the earth if x is an angle in degrees.  (This
* is about 1000 times more resolution than we get with angles around 90
* degrees.)  We use this to avoid having to deal with near singular
* cases when x is non-zero but tiny (e.g., 1.0e-200).
* input
      double precision x

      double precision y, z
      z = 1/16d0
      y = abs(x)
* The compiler mustn't "simplify" z - (z - y) to y
      if (y .lt. z) y = z - (z - y)
      x = sign(y, x)
      AngRnd = x

      return
      end

      subroutine swap(x, y)
* input/output
      double precision x, y

      double precision z
      z = x
      x = y
      y = z
      return
      end

      double precision function hypotx(x, y)
* input
      double precision x, y

      hypotx = sqrt(x**2 + y**2)
      return
      end

      subroutine Norm(sinx, cosx)
* input/output
      double precision sinx, cosx

      double precision hypotx, r
      r = hypotx(sinx, cosx)
      sinx = sinx/r
      cosx = cosx/r
      return
      end

      double precision function log1px(x)
* input
      double precision x

      double precision csmgt, y, z
      y = 1 + x
      z = y - 1
      log1px = csmgt(x, x * log(y) / z, z .eq. 0)
      return
      end

      double precision function atanhx(x)
* input
      double precision x

      double precision log1px, y
      y = abs(x)
      y = log1px(2 * y/(1 - y))/2
      atanhx = sign(y, x)
      return
      end

      double precision function cbrt(x)
* input
      double precision x

      cbrt = sign(abs(x)**(1/3d0), x)
      return
      end

      double precision function csmgt(x, y, p)
* input
      double precision x, y
      logical p

      if (p) then
        csmgt = x
      else
        csmgt = y
      end if
      return
      end

      double precision function TrgSum(sinp, sinx, cosx, c, n)
* Evaluate
* y = sinp ? sum(c[i] * sin( 2*i    * x), i, 1, n) :
*            sum(c[i] * cos((2*i-1) * x), i, 1, n)
* using Clenshaw summation.
* Approx operation count = (n + 5) mult and (2 * n + 2) add
* input
      logical sinp
      integer n
      double precision sinx, cosx, c(n)

      double precision ar, y0, y1
      integer n2, k

* 2 * cos(2 * x)
      ar = 2 * (cosx - sinx) * (cosx + sinx)
* accumulators for sum
      if (mod(n, 2) .eq. 1) then
        y0 = c(n)
        n2 = n - 1
      else
        y0 = 0
        n2 = n
      end if
      y1 = 0
* Now n2 is even
      do 10 k = n2, 1, -2
* Unroll loop x 2, so accumulators return to their original role
        y1 = ar * y0 - y1 + c(k)
        y0 = ar * y1 - y0 + c(k-1)
 10   continue
      if (sinp) then
* sin(2 * x) * y0
        TrgSum = 2 * sinx * cosx * y0
      else
* cos(x) * (y0 - y1)
        TrgSum = cosx * (y0 - y1)
      end if

      return
      end

      integer function trnsit(lon1, lon2)
* input
      double precision lon1, lon2

      double precision lon1x, lon2x, lon12, AngNm, AngDif
      lon1x = AngNm(lon1)
      lon2x = AngNm(lon2)
      lon12 = AngDif(lon1x, lon2x);
      trnsit = 0
      if (lon1 .lt. 0 .and. lon2 .ge. 0 .and. lon12 .gt. 0) then
        trnsit = 1
      else if (lon2 .lt. 0 .and. lon1 .ge. 0 .and. lon12 .lt. 0) then
        trnsit = -1
      end if
      return
      end

* Table of name abbreviations to conform to the 6-char limit
*    A3coeff       A3cof
*    C3coeff       C3cof
*    C4coeff       C4cof
*    AngNormalize  AngNm
*    AngNormalize2 AngNm2
*    AngDiff       AngDif
*    AngRound      AngRnd
*    arcmode       arcmod
*    Astroid       Astrd
*    betscale      betscl
*    lamscale      lamscl
*    cbet12a       cbt12a
*    sbet12a       sbt12a
*    epsilon       dbleps
*    realmin       dblmin
*    geodesic      geod
*    inverse       invers
*    InverseStart  InvSta
*    Lambda12      Lam12f
*    latsign       latsgn
*    lonsign       lonsgn
*    Lengths       Lengs
*    meridian      merid
*    outmask       omask
*    shortline     shortp
*    SinCosNorm    Norm
*    SinCosSeries  TrgSum
*    xthresh       xthrsh
*    transit       trnsit
