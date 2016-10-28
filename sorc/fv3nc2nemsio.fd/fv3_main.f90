program fv3_main
  use fv3_module
  use netcdf
  use nemsio_module   
  implicit none

  type(nemsio_gfile)         :: gfile
  type(nemsio_meta)          :: meta_nemsio
  integer,parameter          :: nvar2d=48,nvar3d=9
  character(nemsio_charkind) :: name2d(nvar2d),name3din(nvar3d)
  character(nemsio_charkind) :: name3dout(nvar3d),varname,levtype
  character(len=300)                        :: inpath,outpath
  character(len=100)                        ::infile2d,infile3d,outfile
  character(len=10) :: analdate
  character(len=3) :: cfhr
  real , allocatable  :: lons(:),lats(:),tmp2d(:,:), tmp2dx(:,:)
  real*8,allocatable :: tmp1d(:),tmp1dx(:),fhours(:)
  
  integer :: ii,i,j,k,ncid2d,ncid3d,ifhr,nlevs,nlons,nlats,ntimes,nargs,iargc,YYYY,MM,DD,HH,stat,varid

  data name2d /'ALBDOsfc','CPRATsfc','PRATEsfc','DLWRFsfc','ULWRFsfc','DSWRFsfc','USWRFsfc','DSWRFtoa','USWRFtoa',&
               'ULWRFtoa','GFLUXsfc','HGTsfc','HPBLsfc',&
               'ICECsfc','SLMSKsfc','LHTFLsfc','SHTFLsfc','PRESsfc','PWATclm','SOILM','SOILW1','SOILW2','SOILW3','SOILW4','SPFH2m',&
	       'SOILT1','SOILT2','SOILT3','SOILT4','TMP2m','TMPsfc','UGWDsfc','VGWDsfc','UFLXsfc','VFLXsfc','UGRD10m','VGRD10m',&
	       'WEASDsfc','SNODsfc','ZORLsfc','VFRACsfc','F10Msfc','VTYPEsfc','STYPEsfc',&
               'TCDCclm', 'TCDChcl', 'TCDClcl', 'TCDCmcl'/

  data name3din /'ucomp','vcomp','temp','sphum','o3mr','nhpres','w','clwmr','delp'/
  data name3dout /'ugrd','vgrd','tmp','spfh','o3mr','pres','vvel','clwmr','dpres'/
    !=====================================================================
 
   ! read in from command line
   nargs=iargc()
   IF (nargs .NE. 7) THEN
      print*,'usage fv3_interface analdate time_slice  inpath infile2d infile3d outpath,outfile'
      STOP
   ENDIF
   call getarg(1,analdate)
   call getarg(2,cfhr)
   call getarg(3,inpath)
   call getarg(4,infile2d)
   call getarg(5,infile3d)
   call getarg(6,outpath)
   call getarg(7,outfile)
   
   read(cfhr,'(i3.1)')  ifhr 
   read(analdate(1:4),'(i4)')  YYYY
   read(analdate(5:6),'(i2)')  MM
   read(analdate(7:8),'(i2)')  DD
   read(analdate(9:10),'(i2)') HH

    ! open netcdf files
    print*,'reading',trim(inpath)//'/'//trim(infile2d)
    stat = nf90_open(trim(inpath)//'/'//trim(infile2d),NF90_NOWRITE, ncid2d)
    if (stat .NE.0) print*,stat
    print*,'reading',trim(inpath)//'/'//trim(infile3d)
    stat = nf90_open(trim(inpath)//'/'//trim(infile3d),NF90_NOWRITE, ncid3d)
    if (stat .NE.0) print*,stat
    ! get dimesions

    stat = nf90_inq_dimid(ncid2d,'time',varid)
    if (stat .NE.0) print*,stat,varid
    if (stat .NE. 0) STOP
    stat = nf90_inquire_dimension(ncid2d,varid,len=ntimes)
    if (stat .NE.0) print*,stat,ntimes
    if (stat .NE. 0) STOP
    allocate(fhours(ntimes))
    stat = nf90_inq_varid(ncid2d,'time',varid)
    if (stat .NE. 0) STOP
    stat = nf90_get_var(ncid2d,varid,fhours)
    if (stat .NE.0) print*,stat,fhours
    if (stat .NE. 0) STOP
    
    stat = nf90_inq_dimid(ncid3d,'grid_xt',varid)
    if (stat .NE.0) print*,stat,varid
    if (stat .NE. 0) STOP
    stat = nf90_inquire_dimension(ncid3d,varid,len=nlons)
    if (stat .NE.0) print*,stat,nlons
    if (stat .NE. 0) STOP
    allocate(lons(nlons))
    allocate(tmp1d(nlons))
    stat = nf90_inq_varid(ncid3d,'grid_xt',varid)
    if (stat .NE. 0) STOP
    stat = nf90_get_var(ncid3d,varid,tmp1d)
    if (stat .NE.0) print*,stat
    if (stat .NE. 0) STOP

    lons=real(tmp1d,kind=4)
    !print*,lons(1),lons(3072)
    deallocate(tmp1d)
    
    stat = nf90_inq_dimid(ncid3d,'grid_yt',varid)
    if (stat .NE.0) print*,stat
    if (stat .NE. 0) STOP
    stat = nf90_inquire_dimension(ncid3d,varid,len=nlats)
    if (stat .NE.0) print*,stat
    if (stat .NE. 0) STOP
    allocate(lats(nlats))
    allocate(tmp1d(nlats))
    allocate(tmp1dx(nlats))
    stat = nf90_inq_varid(ncid3d,'grid_yt',varid)
    stat = nf90_get_var(ncid3d,varid,tmp1dx,start=(/1/),count=(/nlats/))
    if (stat .NE.0) print*,stat
    if (stat .NE. 0) STOP
     do j=1,nlats
      tmp1d(j)=tmp1dx(nlats-j+1)
     enddo
    lats=real(tmp1d,kind=4)
    print*,"lats_beg, lats_end",lats(1),lats(nlats)
    deallocate(tmp1d, tmp1dx)
    
    stat = nf90_inq_dimid(ncid3d,'pfull',varid)
    if (stat .NE.0) print*,stat
    if (stat .NE. 0) STOP
    stat = nf90_inquire_dimension(ncid3d,varid,len=nlevs)
    if (stat .NE.0) print*,stat
    if (stat .NE. 0) STOP
    
   call define_nemsio_meta(meta_nemsio,nlons,nlats,nlevs,nvar2d,lons,lats)

   allocate (tmp2d(nlons,nlats))
   allocate (tmp2dx(nlons,nlats))

   meta_nemsio%idate(1)=YYYY
   meta_nemsio%idate(2)=MM
   meta_nemsio%idate(3)=DD
   if (ifhr.EQ.0) then
      meta_nemsio%varrval(1)=0.0
   else
      meta_nemsio%varrval(1)=(ifhr-1.0)*6.0
   endif

   ! read in data
   meta_nemsio%nfhour= fhours(ifhr)
   meta_nemsio%fhour= fhours(ifhr)
   print*,fhours(ifhr),ifhr,'calling netcdf read'

   call nems_write_init(outpath,outfile,analdate,meta_nemsio,gfile)
! read in all of the 2d variables   and write out
   print*,'calling write',meta_nemsio%rlat_min,meta_nemsio%rlat_max
   print*,'lats',minval(meta_nemsio%lat),maxval(meta_nemsio%lat)
   print *,'loop over 2d variables'
   DO i=1,nvar2d
      print *,i,trim(name2d(i))
      call fv3_netcdf_read_2d(ncid2d,ifhr,meta_nemsio,name2d(i),tmp2dx)
      do ii=1,nlons
      do j=1,nlats
        tmp2d(ii,j)=tmp2dx(ii,nlats-j+1)
      enddo
      enddo
      IF (trim(name2d(i)).EQ.'HGTsfc') then 
          tmp2d=tmp2d/9.81
      ENDIF
      call nems_write(gfile,meta_nemsio%recname(i),meta_nemsio%reclevtyp(i),meta_nemsio%reclev(i), &
           nlons*nlats,tmp2d,stat)
   ENDDO
   levtype='mid layer'
! loop through 3d fields
   print *,'loop over 3d variables'
   DO i=1,nvar3d     
      print*,i,trim(name3din(i))
      DO k=1,nlevs
!         print*,k
         call fv3_netcdf_read_3d(ncid3d,ifhr,meta_nemsio,name3din(i),k,tmp2dx)
         do ii=1,nlons
         do j=1,nlats
           tmp2d(ii,j)=tmp2dx(ii,nlats-j+1)
         enddo
         enddo
         call nems_write(gfile,name3dout(i),levtype,nlevs-k+1,nlons*nlats,tmp2d(:,:),stat)
	 IF (stat .NE. 0) then
             print*,'error writing ,named3dout(i)',stat
             STOP
         ENDIF    
      ENDDO
   ENDDO
 
   call nemsio_close(gfile,iret=stat)
   stat = nf90_close(ncid2d)
   stat = nf90_close(ncid3d)

   deallocate(tmp2dx,tmp2d)

   stop
end program fv3_main
