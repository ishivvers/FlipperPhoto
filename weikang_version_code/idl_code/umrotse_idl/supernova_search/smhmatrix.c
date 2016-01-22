#include <stdlib.h>
#include <stdio.h>


int smhmatrix(int argc,void *argv[])
{
  double *im1_conv=(double*)argv[0];
  double *im2_conv=(double*)argv[1];
  int *indmask=(int*)argv[2];
  int nmask=*(int*)argv[3];
  int n_convolve=*(int*)argv[4];
  double r4_weight=*(double*)argv[5];
  int width=*(int*)argv[6];
  int height=*(int*)argv[7];
  int nk=*(int*)argv[8];
  int *xoff=(int*)argv[9];
  int *yoff=(int*)argv[10];
  double *ikernels=(double*)argv[11];
  double *matrix11=(double*)argv[12];
  double *matrix22=(double*)argv[13];
  double *matrix21=(double*)argv[14];

  int nch,nc,nc2;
  nch=(int)(n_convolve/2);
  nc=(int)(nch*2+1);
  nc2=(int)(nc*nc);
       
  int i,j,framej,framei,k,indim,indmtxj,indmtx,isize,indcov,indcovj,indcovi,indmtx2;
  double widterm;

  isize=width*height;
  for (j=0;j<nk;j++)
    { 
      framej=j*isize;
      indmtxj=j*nk;
      for (i=j;i<nk;i++)
	{
	  framei=i*isize;
	  indmtx=i+indmtxj;
	  widterm=0.0;
	  for (k=0;k<nc2;k++)
	    {
	      widterm=widterm+((double)(xoff[k]*xoff[k]+yoff[k]*yoff[k]))*((double)(xoff[k]*xoff[k]+yoff[k]*yoff[k]))*ikernels[j*nc2+k]*ikernels[i*nc2+k];
	    }
	  *(matrix11+indmtx)=r4_weight*(double)widterm;
	  *(matrix22+indmtx)=r4_weight*(double)widterm;
	  
	  *(matrix21+indmtx)=0.0;
	  
	  for (indim=0;indim<nmask;indim++)
	    {
	      indcov=indmask[indim];
	      indcovj=framej+indmask[indim];
	      indcovi=framei+indmask[indim];
	      *(matrix11+indmtx)+=(double)im1_conv[indcovj]*(double)im1_conv[indcovi];
	      *(matrix22+indmtx)+=(double)im2_conv[indcovj]*(double)im2_conv[indcovi];
	      *(matrix21+indmtx)-=(double)im1_conv[indcovj]*(double)im2_conv[indcovi];
	    }
	}
	      
      for (i=0;i<j;i++)
	{
	  indmtx2=j+i*nk;
	  indmtx=i+indmtxj;
	  framei=i*isize;
	   *(matrix11+indmtx)=*(matrix11+indmtx2);
	   *(matrix22+indmtx)=*(matrix22+indmtx2);
	   *(matrix21+indmtx)=0.0;
 
	  for (indim=0;indim<nmask;indim++)
	    {
	      *(matrix21+indmtx)-=(double)im1_conv[framej+indmask[indim]]*(double)im2_conv[framei+indmask[indim]];
	    }
	}
      
    }
}


