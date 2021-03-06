c-----------------------------------------------------------------------
c     Testing module for the Homogeneoua Anisotropic Hardening model
c
c     Youngung Jeong
c     youngung.jeong@gmail.com

c     Arguments
c     1st argument: the ccw angle that defines the
c                     microstructure deviator in the pi-plane
c     2nd argument: gL
c     3rd argument: gS
c     4th argument: f1
c     5th argument: f2
c-----------------------------------------------------------------------
      program test
      implicit none
      integer ntens,ndi,nshr,nyldc,nyldp,narg
      parameter(ntens=3,ndi=2,nshr=1,nyldc=9,nyldp=50,narg=5)
      character(len=32) :: arg
      dimension yldc(nyldc),yldp(nyldp),stress(ntens),dphi(ntens),
     $     d2phi(ntens,ntens)
      real*8 yldc,yldp,stress,phi,dphi,d2phi,phi_chi
      integer iyld_choice
c     local - microstructure deviator
      dimension emic(ntens),demic(ntens),krs(4),target(ntens)
      real*8 emic,demic,krs,target,dgr
c     local - Bauschinger parameters
      dimension gk(4)
      dimension e_ks(5),aux_ten(ntens)
      dimension f_ks(2)
      real*8 gk,e_ks,f_ks,eeq,aux_ten
c     local - Latent hardening parameters
      real*8 gL,ekL,eL
c     local - cross hardening parameters
      real*8 gS,c_ks,ss
c     local - gen
      real*8 ref0,ref1,hydro
c     local - controlling
      integer imsg,i
      dimension arg_status(narg)
      logical idiaw,arg_status
c     arguments
      real*8 th_emic,pi
      pi = 4d0*datan(1d0)
      idiaw=.false.
c      idiaw = .true.
      imsg  = 0
c     create a dummy microstructure deviator
      aux_ten(:) = 0d0
      aux_ten(1) = 1d0
c      aux_ten(1) = 1d0
      call deviat(ntens,aux_ten,emic,hydro)
      call dev_norm(ntens,ndi,nshr,emic)
c     Default state variables (isotropic conditions)
      gL      = 1d0
      gS      = 1d0
      e_ks(:) = 1d0             ! k1,k2,k3,k4,k5
      f_ks(:) = 0d0             ! f1, f2 that are functions of (k1,k2,k3,k4,k5)
      f_ks(1) = 0d0             ! f1, f2 that are functions of (k1,k2,k3,k4,k5)

      do 5 i=1,narg
         arg_status(i)=.false.
         call getarg(i,arg)
         if (arg.ne.'') arg_status(i)=.true.
c        First argument (th of emic in pi-plane)
         if    (i.eq.1.and.arg_status(i)) then
            read(arg,'(f13.9)') th_emic
            th_emic = th_emic * pi/180d0
            aux_ten(:)=0d0
            aux_ten(1)=dcos(th_emic)
            aux_ten(2)=dsin(th_emic)
            call deviat(ntens,aux_ten,emic,hydro)
            call dev_norm(ntens,ndi,nshr,emic)
         elseif(i.eq.2.and.arg_status(i)) then
            read(arg,'(f13.9)') gL
         elseif(i.eq.3.and.arg_status(i)) then
            read(arg,'(f13.9)') gS
         elseif(i.eq.4.and.arg_status(i)) then
            read(arg,'(f13.9)') f_ks(1)
         elseif(i.eq.5.and.arg_status(i)) then
            read(arg,'(f13.9)') f_ks(2)
         endif
 5    continue
c      call read_alpha(
c     $     '/home/younguj/repo/abaqusPy/umats/yld/alfas.txt',yldc)
      yldc(:8) = 1d0
      yldc(9)  = 2d0
      call hah_io(1,nyldp,ntens,yldp,emic,demic,dgr,gk,e_ks,f_ks,eeq,
     $     ref0,ref1,gL,ekL,eL,gS,c_ks,ss,krs,target)
      iyld_choice=2             ! yld2000-2d
      if (idiaw) call fill_line(imsg,'*',72)
      stress(:)=0d0
      stress(1)=1d0
      if (idiaw) then
         call w_chr(imsg,'cauchy stress')
         call w_dim(imsg,stress,ntens,1d0,.true.)
         call w_chr(imsg,'yldc')
         call w_dim(imsg,yldc,nyldc,1d0,.true.)
         call fill_line(imsg,'*',72)
         call w_chr(imsg,'cauchy stress')
         call w_dim(imsg,stress,ntens,1d0,.true.)
         call w_chr(imsg,'just before entering hah')
      endif
      call hah(iyld_choice,ntens,ndi,nshr,nyldc,nyldp,stress,yldc,yldp,
     $     phi,dphi,d2phi)
      if (idiaw) then
         call w_chr( imsg,'right after exit hah')
         call w_ival(imsg,'iyld_choice:',iyld_choice)
         call w_val( imsg,'phi_chi    :',phi_chi)
         call w_val( imsg,'phi        :',phi)
         call fill_line(imsg,'*',72)
      endif

c      call hah_uten(iyld_choice,ntens,ndi,nshr,nyldc,nyldp,yldc,yldp)
c      call hah_locus(iyld_choice,ntens,ndi,nshr,nyldc,nyldp,yldc,yldp)
      call one(iyld_choice,nyldc,nyldp,yldc,yldp)



      end program test
c--------------------------------------------------------------------------------
      subroutine hah_uten(iyld_choice,ntens,ndi,nshr,nyldc,nyldp,yldc,
     $     yldp)
      implicit none
c     Arguments passed into
      integer ntens,ndi,nshr,nyldc,nyldp
      dimension yldc(nyldc),yldp(nyldp)
      real*8 yldc,yldp
      integer iyld_choice
c     local variables.
      dimension dphi(ntens),d2phi(ntens,ntens),s33lab(3,3),s33mat(3,3),
     $     s6mat(6),dphi33m(3,3),s3mat(3),dphi33l(3,3),
     $     s6lab(6),dphi6(6)
      real*8 dphi,d2phi,pi,th,s33lab,s33mat,s6mat,time0,time1,
     $     dphi33m,s3mat,dphi33l,rv,dphi6,s6lab,phim
      integer nth,i,j,iverbose
c     local - Latent hardening parameters
c      dimension e_ks(5),f_ks(2),gk(4)
c      real*8 gL,ekL,eL,e_ks,f_ks,gk
c     local - cross hardening parameters
c      real*8 gS,c_ks,ss,eeq
c     local - gen
      parameter(nth=10,iverbose=0)

      pi=4.d0*datan(1.d0)
      call cpu_time(time0)
      if (ntens.ne.3) then
         write(*,*)' *********************************************'
         write(*,*)' Warning: case that ntens not equal 3 was not '
         write(*,*)' throughly considered in hah_test.hah_uten    '
         write(*,*)' *********************************************'
         call exit(-1)
      endif
      s6lab(:)=0d0
      s6lab(1)=1d0
      call voigt2(s6lab,s33lab)

      write(*,*)
      write(*,*)

      if (iverbose.eq.1)  then
         write(*,'(a7,5(4a7,x,a1,x),2a7)')'th',
     $        's11_l','s22_l','s33_l','s12_l','|',
     $        's11_m','s22_m','s33_m','s12_m','|',
     $        's11_l','s22_l','s33_l','s12_l','|',
     $        'e11_m','e22_m','e33_m','e12_m','|',
     $        'e11_l','e22_l','e33_l','e12_l','|',
     $        'rv','phim'
      elseif (iverbose.eq.0)  then
         write(*,'(3a7)') 'th','rv','phim'
      endif

      do 10 j=1,nth
         th = pi/2d0 - pi/2d0/(nth-1)*(j-1)
         if (iverbose.ge.0) write(*,'(f7.2)',advance='no') th*180.d0/pi
         if (iverbose.eq.1) then
            write(*,'(4f7.2,x,a1,x)',advance='no')
     $           (s33lab(i,i),i=1,3),s33lab(1,2),'|'
         endif
         call inplane_rot(th,s33lab,s33mat)
         if (iverbose.eq.1) then
            write(*,'(4f7.2,x,a1,x)',advance='no')
     $           (s33mat(i,i),i=1,3),s33mat(1,2),'|'
         endif
         call inplane_rot(th*(-1d0),s33mat,s33lab)
         if (iverbose.eq.1) then
            write(*,'(4f7.2,x,a1,x)',advance='no')
     $           (s33lab(i,i),i=1,3),s33lab(1,2),'|'
         endif
         call voigt1(s33mat,s6mat)
         call reduce_6to3(s6mat,s3mat)
         call hah(iyld_choice,ntens,ndi,nshr,nyldc,nyldp,
     $        s3mat,yldc,yldp,phim,dphi,d2phi)
         if (ntens.eq.3) then
            call reduce_3to6(dphi,dphi6)
            dphi6(3) = -dphi(1)-dphi(2)
            call voigt4(dphi6,dphi33m) !! this is wrong.
         elseif (ntens.eq.6) then
            call voigt4(dphi,dphi33m) !! this is wrong.
         else
            call exit(-1)
         endif
!        dphi in material axes
         if (iverbose.eq.1) then
            write(*,'(4f7.2,x,a1,x)',advance='no')
     $           (dphi33m(i,i),i=1,3),dphi33m(1,2),'|'
         endif
         call inplane_rot(th*(-1.d0),dphi33m,dphi33l)
         rv =-dphi33l(2,2)/(dphi33l(1,1)+dphi33l(2,2))
         if (iverbose.eq.1) then
            write(*,'(4f7.2,x,a1,x)',advance='no')
     $           (dphi33l(i,i),i=1,3),dphi33l(1,2),'|'
         endif
         if(iverbose.ge.0) then
            write(*,'(2f7.2)',advance='no') rv,phim
            write(*,*)
         endif
 10   continue
      call cpu_time(time1)
      return
      end subroutine hah_uten
c-----------------------------------------------------------------------
c     Subroutine to draw yield locus
      subroutine hah_locus(iyld_choice,ntens,ndi,nshr,nyldc,nyldp,
     $     yldc,yldp)
c     Arguments
c     iyld_choice: yield function choice
c     ntens      : Len of tensor
c     ndi        : Number of normal components
c     nshr       : Number of shear components
c     nyldc      : Len of yldc
c     nyldp      : Len of yldp
c     yldc       : yield function constants
c     yldp       : yield function parameters
      implicit none
c     Arguments passed into
      integer, intent(in) :: iyld_choice
      integer, intent(in) :: ntens,ndi,nshr,nyldc,nyldp
      dimension yldc(nyldc),yldp(nyldp)
      real*8, intent(in) :: yldc
      real*8 yldp
c     Local variables.
      dimension d2phi(ntens),smat(ntens),dphi(ntens),sdev(6),aux6(6)
      real*8 dphi,d2phi,pi,th,time0,time1,phim,q,smat,sdev,hydro,s1,s2,
     $     aux6
      integer nth,i,j,imsg,iverbose
      parameter(nth=10)
      logical idiaw
      imsg = 0
      iverbose=0  ! (0: fully verbose)
                  ! (1:)
      idiaw = .true.

      call cpu_time(time0)
      open(1,file='hah.txt',status='unknown')

c     pi and yield surface exponent q stored in yldc
      pi=4.d0*datan(1.d0)
      q = yldc(9)

      if (idiaw) then
         write(*,*)
         write(*,*)
         write(*,*)
         write(*,'(5a9)')'s1','s2','e1','e2','phi'
      endif
c$$$         write(*,'(a11,x,(4a9,x,a1,x),2(4a11,x,a1,x,a11,x))')'th',
c$$$     $        's1_m', 's2_m', 's3_m', 's6_m', '|',
c$$$     $        'e11_m','e22_m','e33_m','e12_m','|','phim',
c$$$     $        's1_m', 's2_m', 's3_m', 's6_m', '|','phim'

      do 10 j=1,nth
         th = 2*pi/(nth-1)*(j-1)
c         write(*,'(f7.1,a)',advance='no') th*180.d0/pi,'|'
         if (ntens.eq.3) then
            smat(1)   = dcos(th)
            smat(2)   = dsin(th)
            smat(3:ntens)   = 0.
         elseif (ntens.eq.6) then
            smat(1)   = dcos(th)
            smat(2)   = dsin(th)
            smat(3:ntens)   = 0.
         else
            write(*,*) 'unexpected dimension of ntens'
            call exit(-1)
         endif

c         call w_dim(imsg,smat,ntens,1d0,.false.)
c         call w_chrc(imsg,'|')
         call hah(iyld_choice,ntens,ndi,nshr,nyldc,nyldp,smat,yldc,yldp,
     $        phim,dphi,d2phi)
c         call w_dim(0,smat,ntens,1d0,.false.)
c         call w_dim(imsg,dphi,ntens,1d0,.false.)
c         call w_chrc(imsg,'|')
c         call w_valsc(imsg,phim)
c         call w_chrc(imsg,'|')
         do i=1,ntens
            smat(i) = smat(i)*phim
         enddo
         call hah(iyld_choice,ntens,ndi,nshr,nyldc,nyldp,smat,yldc,yldp,
     $        phim,dphi,d2phi)
         if (ntens.eq.3) then
            call reduce_3to6(smat,aux6)
            call deviat(6,aux6,sdev,hydro)
         elseif (ntens.eq.6) then
            call deviat(6,smat,sdev,hydro)

         else
            write(*,*)'unexpected case of ntens in hah_locus'
            call exit(-1)
         endif

         call pi_proj(sdev,s1,s2)

         if (idiaw) then
            write(*,'(2f9.5)',advance='no') (smat(i),i=1,2)
            write(*,'(3f9.5)',advance='no') (dphi(i),i=1,2),phim
            write(*,*)
         endif
         write(1,'(6f7.3)',advance='no') smat(1),smat(2),dphi(1),
     $        dphi(2),s1,s2
         write(1,*)
 10   continue

      call cpu_time(time1)
      write(*,'(a,f9.1)') 'Elapsed time: [\mu s]',
     $     (time1-time0)*1e6
      close(1)
      return
      end subroutine hah_locus
c--------------------------------------------------------------------------------
c     Test one stress state
      subroutine one(iyld_choice,nyldc,nyldp,yldc,yldp)
      implicit none
c     Arguments passed into
      integer ntens,ndi,nshr
      parameter(ntens=3,ndi=2,nshr=1)
      integer, intent(in)::iyld_choice,nyldc,nyldp
      dimension yldc(nyldc),yldp(nyldp),
     $     d2phi(ntens,ntens),dphi(ntens),aux_ten(ntens),emic(ntens)
      real*8 yldc,yldp,d2phi,dphi,phi,cauchy(ntens),aux_ten,emic,hydro
      integer imsg
      logical idiaw
      imsg=0
      idiaw=.true.              !.false.

c     microstructure deviator
      aux_ten(:) = 0d0
      aux_ten(1) = 1d0
      aux_ten(1) = 1d0
      call deviat(ntens,aux_ten,emic,hydro)
      call dev_norm(ntens,ndi,nshr,emic)
      if (idiaw) then
         call fill_line(imsg,'-',27)
         call w_chr(imsg,'Microstructure deviator:')
         call w_dim(imsg,emic,ntens,1d0,.true.)

      endif

c     Uniaxial tension along axial 1
      cauchy(:)=0d0
      cauchy(1)=1d0
      call hah(iyld_choice,ntens,ndi,nshr,nyldc,nyldp,cauchy,yldc,yldp,
     $     phi,dphi,d2phi)
      if (idiaw) then
         call fill_line(imsg,'-',27)
         call w_chr(imsg,'         cauchy stress')
         call w_dim(imsg,cauchy,ntens,1d0,.true.)
         call w_val(imsg,'phi:',phi)
         call w_chr(imsg,'    dphi1   dphi2   dphi3')
         call w_dim(imsg,dphi,ntens,1d0,.true.)
      endif

c$$$c     Uniaxial tension along axial 2
c$$$      cauchy(:)=0d0
c$$$      cauchy(2)=1d0
c$$$      call hah(iyld_choice,ntens,ndi,nshr,nyldc,nyldp,cauchy,yldc,yldp,
c$$$     $     phi,dphi,d2phi)
c$$$c     Balanced biaxial tension
c$$$      cauchy(:)=0d0
c$$$      cauchy(1:2)=1d0
c$$$      call hah(iyld_choice,ntens,ndi,nshr,nyldc,nyldp,cauchy,yldc,yldp,
c$$$     $     phi,dphi,d2phi)
      return
      end subroutine one
