c-----------------------------------------------------------------------
      subroutine yld(iyld_law,yldp,yldc,nyldp,nyldc,
     $     stress,phi,dphi,d2phi,ntens)
c-----------------------------------------------------------------------
c***  Arguments
c     iyld_law  : choice of yield function
c     yldp      : state variables associated with yield function
c     yldc      : constants for yield function
c     nyldp     : Len of yldp
c     nyldc     : Len of yldc
c     phi       : yield surface
c     dphi      : 1st derivative of yield surface w.r.t. stress
c     d2phi     : 2nd derivative of yield surface w.r.t. stress
c-----------------------------------------------------------------------
c     intent(in) iyld_law,yldp,yldc,nyldp,nyldc
c     intent(out) phi,dphi,d2phi
c-----------------------------------------------------------------------
      implicit none
      integer iyld_law,nyldp,nyldc,ntens
      dimension yldp(nyldp),yldc(nyldc),dphi(ntens),d2phi(ntens,ntens)
      real*8 yldp,yldc,phi,dphi,d2phi

c***  Local variables for better readibility
      dimension stress(ntens),strain(ntens)
      real*8 stress,strain

c***  Define phi,dphi,d2phi
      if (iyld_law.eq.0) then
         call vm_shell(stress,phi,dphi,d2phi)
      else
         write(*,*)'unexpected iyld_law given'
         stop -1
      endif

      end subroutine yld
c-----------------------------------------------------------------------
      subroutine update_yldp(iyld_law,
     $     yldp_ns,nyldp,deeq)
      implicit none
      integer iyld_law,nyldp,nyldc
      dimension yldp_ns(0:1,nyldp)
      real*8 yldp_ns,eeq

!     update laws.
      if (iyld_law.eq.0) then
         yldp_ns(1,1) = deeq + yldp_ns(0,1)
      else
         write(*,*)'unexpected iyld_law given in update_yldp'
         stop -1
      endif
      end subroutine update_yldp
c-----------------------------------------------------------------------
c     Von Mises
      include "/home/younguj/repo/abaqusPy/umats/lib/vm.f"
