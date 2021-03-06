*> @file signtest.for
*! @brief Test suite for the signs of +/-0 and +/-180 in Fortran
*!
*! Run these tests by configuring with cmake and running "make test".
*!
*! Copyright (c) Charles Karney (2022) <charles@karney.com> and
*! licensed under the MIT/X11 License.  For more information, see
*! https://geographiclib.sourceforge.io/

*> @cond SKIP

      integer function assert(x, y, d)
      double precision x, y, d

      if (abs(x - y) .le. d) then
        assert = 0
      else
        assert = 1
        print 10, x, y, d
 10     format(1x, 'assert fails: ',
     +      g14.7, ' != ', g14.7, ' +/- ', g10.3)
      end if

      return
      end

      integer function chknan(x)
      double precision x

      if (x .ne. x) then
        chknan = 0
      else
        chknan = 1
      end if

      return
      end

      integer function equiv(x, y)
      double precision x, y
      integer i, j, chknan

      i = chknan(x)
      j = chknan(y)
      if ((i .eq. 0 .and. j .eq. 0) .or.
     +    (x .eq. y .and. sign(1d0, x) .eq. sign(1d0, y))) then
        equiv = 0
      else
        equiv = 1
      end if

      return
      end

      integer function chrnd0(x, y)
      double precision x, y, z, AngRnd
      integer equiv

      z = AngRnd(x)
      chrnd0 = equiv(z, y)
      if (chrnd0 .gt. 0) then
        print 10, x, z, y
 10     format(1x, 'AngRound(',
     +      g10.3, ') = ', g10.3, ' not ', g10.3)
      end if

      return
      end

      integer function chrnd()
      integer i, chrnd0
      double precision eps, inf, nan, LatFix

      eps = 0.5d0**(53-1)
      inf = 1d0/LatFix(0d0)
      nan = LatFix(91d0)
      i = 0
      i = i + chrnd0(-eps/32, -eps/32)
      i = i + chrnd0(-eps/64, -0d0   )
      i = i + chrnd0(-  0d0 , -0d0   )
      i = i + chrnd0(   0d0 , +0d0   )
      i = i + chrnd0( eps/64, +0d0   )
      i = i + chrnd0( eps/32, +eps/32)
      i = i + chrnd0((1-2*eps)/64, (1-2*eps)/64)
      i = i + chrnd0((1-eps  )/64,  1d0     /64)
      i = i + chrnd0((1-eps/2)/64,  1d0     /64)
      i = i + chrnd0((1-eps/4)/64,  1d0     /64)
      i = i + chrnd0( 1d0     /64,  1d0     /64)
      i = i + chrnd0((1+eps/2)/64,  1d0     /64)
      i = i + chrnd0((1+eps  )/64,  1d0     /64)
      i = i + chrnd0((1+2*eps)/64, (1+2*eps)/64)
      i = i + chrnd0((1-eps  )/32, (1-eps  )/32)
      i = i + chrnd0((1-eps/2)/32,  1d0     /32)
      i = i + chrnd0((1-eps/4)/32,  1d0     /32)
      i = i + chrnd0( 1d0     /32,  1d0     /32)
      i = i + chrnd0((1+eps/2)/32,  1d0     /32)
      i = i + chrnd0((1+eps  )/32, (1+eps  )/32)
      i = i + chrnd0((1-eps  )/16, (1-eps  )/16)
      i = i + chrnd0((1-eps/2)/16, (1-eps/2)/16)
      i = i + chrnd0((1-eps/4)/16,  1d0     /16)
      i = i + chrnd0( 1d0     /16,  1d0     /16)
      i = i + chrnd0((1+eps/4)/16,  1d0     /16)
      i = i + chrnd0((1+eps/2)/16,  1d0     /16)
      i = i + chrnd0((1+eps  )/16, (1+eps  )/16)
      i = i + chrnd0((1-eps  )/ 8, (1-eps  )/ 8)
      i = i + chrnd0((1-eps/2)/ 8, (1-eps/2)/ 8)
      i = i + chrnd0((1-eps/4)/ 8,  1d0     / 8)
      i = i + chrnd0((1+eps/2)/ 8,  1d0     / 8)
      i = i + chrnd0((1+eps  )/ 8, (1+eps  )/ 8)
      i = i + chrnd0( 1-eps      ,  1-eps      )
      i = i + chrnd0( 1-eps/2    ,  1-eps/2    )
      i = i + chrnd0( 1-eps/4    ,  1d0        )
      i = i + chrnd0( 1d0        ,  1d0        )
      i = i + chrnd0( 1+eps/4    ,  1d0        )
      i = i + chrnd0( 1+eps/2    ,  1d0        )
      i = i + chrnd0( 1+eps      ,  1+  eps    )
      i = i + chrnd0( 90d0-64*eps,  90-64*eps  )
      i = i + chrnd0( 90d0-32*eps,  90d0       )
      i = i + chrnd0( 90d0       ,  90d0       )

      chrnd = i

      return
      end

      integer function chsc0(x, s, c)
      double precision x, s, c, ss, cc
      integer equiv

      call sncsdx(x, ss, cc)
      chsc0 = equiv(ss, s) + equiv(cc, c)
      if (chsc0 .gt. 0) then
        print 10, x, ss, cc, s, c
 10     format(1x, 'sincosd(', g10.3, ') = (', g10.3, ',', g10.3,
     +      ') not (', g10.3, ',', g10.3, ')')
      end if

      return
      end

      integer function chsc()
      integer i, j, chsc0, equiv
      double precision eps, inf, nan, LatFix, s1, c1, s2, c2, s3, c3

      eps = 0.5d0**(53-1)
      inf = 1d0/LatFix(0d0)
      nan = LatFix(91d0)
      i = 0

      i = i + chsc0(-  inf,  nan,  nan)
      i = i + chsc0(-810d0, -1d0, +0d0)
      i = i + chsc0(-720d0, -0d0, +1d0)
      i = i + chsc0(-630d0, +1d0, +0d0)
      i = i + chsc0(-540d0, -0d0, -1d0)
      i = i + chsc0(-450d0, -1d0, +0d0)
      i = i + chsc0(-360d0, -0d0, +1d0)
      i = i + chsc0(-270d0, +1d0, +0d0)
      i = i + chsc0(-180d0, -0d0, -1d0)
      i = i + chsc0(- 90d0, -1d0, +0d0)
      i = i + chsc0(-  0d0, -0d0, +1d0)
      i = i + chsc0(+  0d0, +0d0, +1d0)
      i = i + chsc0(+ 90d0, +1d0, +0d0)
      i = i + chsc0(+180d0, +0d0, -1d0)
      i = i + chsc0(+270d0, -1d0, +0d0)
      i = i + chsc0(+360d0, +0d0, +1d0)
      i = i + chsc0(+450d0, +1d0, +0d0)
      i = i + chsc0(+540d0, +0d0, -1d0)
      i = i + chsc0(+630d0, -1d0, +0d0)
      i = i + chsc0(+720d0, +0d0, +1d0)
      i = i + chsc0(+810d0, +1d0, +0d0)
      i = i + chsc0(+  inf,  nan,  nan)
      i = i + chsc0(   nan,  nan,  nan)

      call sncsdx(         9d0, s1, c1)
      call sncsdx(        81d0, s2, c2)
      call sncsdx(-123456789d0, s3, c3)
      j = equiv(s1, c2) + equiv(s1, s3) + equiv(c1, s2) + equiv(c1, -c3)
      if (j .gt. 0) print *, 'sincos accuracy failure'
      i = i + j

      chsc = i

      return
      end

      integer function chat0(y, x, a)
      double precision y, x, a, aa, atn2dx
      integer equiv

      aa = atn2dx(y, x)
      chat0 = equiv(aa, a)
      if (chat0 .gt. 0) then
        print 10, y, x, aa, a
 10     format(1x, 'atan2d(', g10.3, ',', g10.3, ') = ', g10.3,
     +      ' not ', g10.3)
      end if

      return
      end

      integer function chat()
      integer i, j, chat0, equiv
      double precision eps, inf, nan, LatFix, s, atn2dx

      eps = 0.5d0**(53-1)
      inf = 1d0/LatFix(0d0)
      nan = LatFix(91d0)
      i = 0

      i = i + chat0(+0d0 , -0d0 , +180d0)
      i = i + chat0(-0d0 , -0d0 , -180d0)
      i = i + chat0(+0d0 , +0d0 ,   +0d0)
      i = i + chat0(-0d0 , +0d0 ,   -0d0)
      i = i + chat0(+0d0 , -1d0 , +180d0)
      i = i + chat0(-0d0 , -1d0 , -180d0)
      i = i + chat0(+0d0 , +1d0 ,   +0d0)
      i = i + chat0(-0d0 , +1d0 ,   -0d0)
      i = i + chat0(-1d0 , +0d0 ,  -90d0)
      i = i + chat0(-1d0 , -0d0 ,  -90d0)
      i = i + chat0(+1d0 , +0d0 ,  +90d0)
      i = i + chat0(+1d0 , -0d0 ,  +90d0)
      i = i + chat0(+1d0 ,  -inf, +180d0)
      i = i + chat0(-1d0 ,  -inf, -180d0)
      i = i + chat0(+1d0 ,  +inf,   +0d0)
      i = i + chat0(-1d0 ,  +inf,   -0d0)
      i = i + chat0( +inf, +1d0 ,  +90d0)
      i = i + chat0( +inf, -1d0 ,  +90d0)
      i = i + chat0( -inf, +1d0 ,  -90d0)
      i = i + chat0( -inf, -1d0 ,  -90d0)
      i = i + chat0( +inf,  -inf, +135d0)
      i = i + chat0( -inf,  -inf, -135d0)
      i = i + chat0( +inf,  +inf,  +45d0)
      i = i + chat0( -inf,  +inf,  -45d0)
      i = i + chat0(  nan, +1d0 ,    nan)
      i = i + chat0(+1d0 ,   nan,    nan)

      s = 7d-16
      j = equiv(atn2dx(s, -1d0), 180 - atn2dx(s, 1d0));
      if (j .gt. 0) print *, 'atan2d accuracy failure'
      i = i + j

      chat = i

      return
      end

      integer function chsm0(x, y, z)
      double precision x, y, z, zz, sumx, t
      integer equiv

      zz = sumx(x, y, t)
      chsm0 = equiv(zz, z)
      if (chsm0 .gt. 0) print 10, x, y, zz, z
 10   format(1x, 'sum(', g10.3, ',', g10.3, ') = ', g10.3,
     +    ' not ', g10.3)

      return
      end

      integer function chsm()
      integer i, chsm0

      i = 0

      i = i + chsm0(+9d0, -9d0, +0d0 )
      i = i + chsm0(-9d0, +9d0, +0d0 )
      i = i + chsm0(-0d0, +0d0, +0d0 )
      i = i + chsm0(+0d0, -0d0, +0d0 )
      i = i + chsm0(-0d0, -0d0, -0d0 )
      i = i + chsm0(+0d0, +0d0, +0d0 )

      chsm = i

      return
      end

      integer function chnm0(x, y)
      double precision x, y, yy, AngNm
      integer equiv

      yy = AngNm(x)
      chnm0 = equiv(yy, y)
      if (chnm0 .gt. 0) print 10, x, yy, y
 10   format(1x, 'AngNormalize(', g10.3, ') = ', g10.3,
     +    ' not ', g10.3)

      return
      end

      integer function chnm()
      integer i, chnm0

      i = 0

      i = i + chnm0(-900d0, -180d0 )
      i = i + chnm0(-720d0,   -0d0 )
      i = i + chnm0(-540d0, -180d0 )
      i = i + chnm0(-360d0,   -0d0 )
      i = i + chnm0(-180d0, -180d0 )
      i = i + chnm0(  -0d0,   -0d0 )
      i = i + chnm0(  +0d0,   +0d0 )
      i = i + chnm0( 180d0, +180d0 )
      i = i + chnm0( 360d0,   +0d0 )
      i = i + chnm0( 540d0, +180d0 )
      i = i + chnm0( 720d0,   +0d0 )
      i = i + chnm0( 900d0, +180d0 )

      chnm = i

      return
      end

      integer function chdf0(x, y, d)
      double precision x, y, d, dd, AngDif, t
      integer equiv

      dd = AngDif(x, y, t)
      chdf0 = equiv(dd, d)
      if (chdf0 .gt. 0) print 10, x, y, dd, d
 10   format(1x, 'AngDiff(', g10.3, ',', g10.3, ') = ', g10.3,
     +    ' not ', g10.3)

      return
      end

      integer function chdf()
      integer i, j, chdf0, equiv
      double precision eps, AngDif, x, y, t

      eps = 0.5d0**(53-1)
      i = 0

      i = i + chdf0(+  0d0, +  0d0, +0d0 )
      i = i + chdf0(+  0d0, -  0d0, -0d0 )
      i = i + chdf0(-  0d0, +  0d0, +0d0 )
      i = i + chdf0(-  0d0, -  0d0, +0d0 )
      i = i + chdf0(+  5d0, +365d0, +0d0 )
      i = i + chdf0(+365d0, +  5d0, -0d0 )
      i = i + chdf0(+  5d0, +185d0, +180d0 )
      i = i + chdf0(+185d0, +  5d0, -180d0 )
      i = i + chdf0( +eps , +180d0, +180d0 )
      i = i + chdf0( -eps , +180d0, -180d0 )
      i = i + chdf0( +eps , -180d0, +180d0 )
      i = i + chdf0( -eps , -180d0, -180d0 )

      x = 138 + 128 * eps
      y = -164
      j = equiv( AngDif(x, y, t), 58 - 128 * eps )
      if ( j .gt. 0 ) print *, 'AngDiff accuracy failure'
      i = i + j

      chdf = i

      return
      end

      integer function tst1()
* azimuth of geodesic line with points on equator determined by signs of
* latitude
      double precision C(3,2)
*          lat1 lat2 azi1/2
      data C /
     +    +0d0, -0d0, 180,
     +    -0d0, +0d0,   0 /
      double precision a, f
      double precision azi1, azi2, s12, a12, m12, MM12, MM21, SS12
      integer i, k, equiv
      include 'geodesic.inc'

* WGS84 values
      a = 6378137d0
      f = 1/298.257223563d0

      i = 0

      do k = 1, 2
        call invers(a, f, C(1, k), 0d0, C(2, k), 0d0,
     +      s12, azi1, azi2, 0, a12, m12, MM12, MM21, SS12)
        i = i + equiv(azi1, C(3, k)) + equiv(azi2, C(3, k))
      end do

      tst1 = i

      return
      end

      integer function tst2()
* Does the nearly antipodal equatorial solution go north or south?
      double precision C(4,2)
*          lat1 lat2 azi1 azi2
      data C /
     +    +0d0, +0d0,  56, 124,
     +    -0d0, -0d0, 124,  56 /
      double precision a, f
      double precision azi1, azi2, s12, a12, m12, MM12, MM21, SS12
      integer i, k, assert
      include 'geodesic.inc'

* WGS84 values
      a = 6378137d0
      f = 1/298.257223563d0

      i = 0

      do k = 1, 2
        call invers(a, f, C(1, k), 0d0, C(2, k), 179.5d0,
     +      s12, azi1, azi2, 0, a12, m12, MM12, MM21, SS12)
        i = i + assert(azi1, C(3, k), 1d0) + assert(azi2, C(4, k), 1d0)
      end do

      tst2 = i

      return
      end

      integer function tst3()
* How does the exact antipodal equatorial path go N/S + E/W
      double precision C(5,4)
*          lat1 lat2 lon2 azi1 azi2
      data C /
     +    +0d0, +0d0, +180,   +0d0, +180,
     +    -0d0, -0d0, +180, +180,   +0d0,
     +    +0d0, +0d0, -180,   -0d0, -180,
     +    -0d0, -0d0, -180, -180,   -0d0 /
      double precision a, f
      double precision azi1, azi2, s12, a12, m12, MM12, MM21, SS12
      integer i, k, equiv
      include 'geodesic.inc'

* WGS84 values
      a = 6378137d0
      f = 1/298.257223563d0

      i = 0

      do k = 1, 4
        call invers(a, f, C(1, k), 0d0, C(2, k), C(3, k),
     +      s12, azi1, azi2, 0, a12, m12, MM12, MM21, SS12)
        i = i + equiv(azi1, C(4, k)) + equiv(azi2, C(5, k))
      end do

      tst3 = i

      return
      end

      integer function tst4()
* Anipodal points on the equator with prolate ellipsoid
      double precision C(2,2)
*          lon2 azi1/2
      data C /
     +    +180, +90,
     +    -180, -90 /
      double precision a, f
      double precision azi1, azi2, s12, a12, m12, MM12, MM21, SS12
      integer i, k, equiv
      include 'geodesic.inc'

* Prolate values
      a = 6.4d6
      f = -1/300d0

      i = 0

      do k = 1, 2
        call invers(a, f, 0d0, 0d0, 0d0, C(1, k),
     +      s12, azi1, azi2, 0, a12, m12, MM12, MM21, SS12)
        i = i + equiv(azi1, C(2, k)) + equiv(azi2, C(2, k))
      end do

      tst4 = i

      return
      end

      integer function tst5()
* azimuths = +/-0 and +/-180 for the direct problem
      double precision C(3,4)
*          azi1, lon2, azi2
      data C /
     +    +0d0, +180, +180 ,
     +    -0d0, -180, -180 ,
     +    +180 , +180, +0d0,
     +    -180 , -180, -0d0 /
      double precision a, f
      double precision lat2, lon2, azi2, a12, m12, MM12, MM21, SS12
      integer i, k, equiv
      include 'geodesic.inc'

* WGS84 values
      a = 6378137d0
      f = 1/298.257223563d0

      i = 0

      do k = 1, 4
        call direct(a, f, 0d0, 0d0, C(1, k), 15d6,
     +      2, lat2, lon2, azi2, 0, a12, m12, MM12, MM21, SS12)
        i = i + equiv(lon2, C(2, k)) + equiv(azi2, C(3, k))
      end do

      tst5 = i

      return
      end

      program signtest
      integer n, i
      integer chrnd, chsc, chat, chsm, chnm, chdf,
     +    tst1, tst2, tst3, tst4, tst5

      n = 0
      call geoini

      i = chrnd()
      if (i .gt. 0) then
        n = n + 1
        print *, 'AngRound fail:', i
      end if

      i = chsc()
      if (i .gt. 0) then
        n = n + 1
        print *, 'sincosd fail:', i
      end if

      i = chat()
      if (i .gt. 0) then
        n = n + 1
        print *, 'atan2d fail:', i
      end if

      i = chsm()
      if (i .gt. 0) then
        n = n + 1
        print *, 'sum fail:', i
      end if

      i = chnm()
      if (i .gt. 0) then
        n = n + 1
        print *, 'AngNormalize fail:', i
      end if

      i = chdf()
      if (i .gt. 0) then
        n = n + 1
        print *, 'AngDiff fail:', i
      end if

      i = tst1()
      if (i .gt. 0) then
        n = n + 1
        print *, 'inverse coincident points on equator fail:', i
      end if

      i = tst2()
      if (i .gt. 0) then
        n = n + 1
        print *, 'inverse nearly antipodal points on equator fail:', i
      end if

      i = tst3()
      if (i .gt. 0) then
        n = n + 1
        print *, 'inverse antipodal points on equator fail:', i
      end if

      i = tst4()
      if (i .gt. 0) then
        n = n + 1
        print *, 'inverse antipodal points on equator, prolate, fail:',
     +      i
      end if

      i = tst5()
      if (i .gt. 0) then
        n = n + 1
        print *, 'direct azi1 = +/-0 +/-180, fail:', i
      end if

      if (n .gt. 0) then
        stop 1
      end if

      stop
      end

*> @endcond SKIP
