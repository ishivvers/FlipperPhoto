/*****************************************************************************/
/*                                                                           */
/*	find_freq.c                                                          */
/*                                                                           */
/*	"find_freq" analyzes a light curve for periodicity using a B-spline  */
/*  least square fitting technique. This program should be invoked with      */
/*  three arguments; the light curve file name, the maximum frequency and    */
/*  number of spline intervals. The light curve data is found in the         */
/*  subdirectory pointed to by the environmental variable, LIGHT_CURVES.     */
/*                                                                           */
/*		Carl W. Akerlof                                              */
/*		Randall Laboratory of Physics                                */
/*		500 East University                                          */
/*		University of Michigan                                       */
/*		Ann Arbor, Michigan  48109                                   */
/*                                                                           */
/*		January 29, 1966                                             */
/*                                                                           */
/*****************************************************************************/

#include <math.h>
#include <stdio.h>
#include <string.h>
#ifdef __DECC
#include <stdlib.h>
#include <time.h>
#include "USR$DISK4:[akerlof.spline]spline_inc.h"
#else
#include <sys/param.h>
#include "spline_inc.h"
#endif
#define ABS(A)  ((A >= 0.0) ? (A) : (-(A)))
#define N_MAX 1000

#ifndef __DECC
/*char *getenv(char *name);*/
/*long int clock();*/
#endif

float spline_pls(struct spline_str *s);

main(int argc, char *argv[])
{
     char c_text, file_name[FILENAME_MAX];
     int chi_idx[4], *chi_index, i, io_status, j, k, nd, n_fits, n_freq,
         n_intervals, n_max, n_min, *phi_index;
#ifdef __DECC
     clock_t t_lapse;
#else
     long int t_lapse;
#endif
     double dy, x, y;
     static int freq_index[NFITS];
     static float freq_chi[NFITS], freq_val[NFITS], wd[N_MAX], xd[N_MAX],
                  yd[N_MAX];
     float chi_h, chi_i, chi_l, chi_m, *chi_sq, chi_vec[4], df, dx, d_freq, f,
           freq_max, phi, u;
     struct spline_str s;
     FILE *file_ptr;
     if (argc != 4)
     {
	  printf("Enter light curve file name, max. frequency and"
		 " # of intervals.\n");
	  exit(1);
     }
#ifdef __DECC
     strcpy(file_name, "LIGHT_CURVES");
     strncat(file_name, ":", FILENAME_MAX);
#else
     strcpy(file_name, getenv("LIGHT_CURVES"));
     strncat(file_name, "/", FILENAME_MAX);
#endif
     strncat(file_name, argv[1], FILENAME_MAX);
     strncat(file_name, ".dat", FILENAME_MAX);
     if ((file_ptr=fopen(file_name, "r")) == NULL)
     {
	  printf("The file, %s, cannot be opened.\n", file_name);
	  exit(1);
     }
     for (i=0; i < 3; i++)
     {
	  do
	  {
	       fscanf(file_ptr, "%c", &c_text);
	  } while (c_text != '\n');
     }
     nd=0;
     while ((io_status=fscanf(file_ptr, "%lf %lf %lf", &x, &y, &dy)) == 3)
     {
	  if (dy > 0.0)
	  {
	       xd[nd] = x;
	       yd[nd] = y;
	       wd[nd] = dy;
	       nd++;
	  }
	  do
	  {
	       fscanf(file_ptr, "%c", &c_text);
	  } while (c_text != '\n');
     }
     if (io_status != EOF)
     {
	  printf("I/O error: %8i\n", io_status);
     }
     fclose(file_ptr);
     sscanf(argv[2], "%f", &freq_max);
     sscanf(argv[3], "%i", &n_intervals);
     if (nd <= n_intervals)
     {
	  printf("Insufficient data in file: %s%4i\n", file_name, nd);
	  exit(1);
     }
/*                                                                           */
/*      Search for periodic behavior                                         */
/*                                                                           */
     dx=xd[nd-1]-xd[0];
     d_freq=0.25/(((float) OVER_SAMPLE)*dx);
     n_freq=((float) 4.0*OVER_SAMPLE)*freq_max*dx+1.0;
     printf("\nFile: %s\nData points:%5i     Time interval:%8.3f\n\n",
	    file_name, nd, dx);
     i=(int) ALIGN(((int*) NULL)+2*n_freq, float);
     i=(int) ALIGN(((float*) i)+n_freq, char);
     s=spline_icy(n_intervals, nd, xd, yd, wd, i);
     chi_index=(int*) s.base_a;
     phi_index=chi_index+n_freq;
     chi_sq=ALIGN(phi_index+n_freq, float);
     if (s.ierr == 0)
     {
	  t_lapse=clock();
	  for (i=0; i < n_freq; i++)
	  {
	       f=((float) i)*d_freq;
	       for (j=0; j < 4; j++)
	       {
		    phi=((float) j)/((float) 4*n_intervals);
		    for (k=0; k < nd; k++)
		    {
			 u=f*(*(s.xt+k)-*s.xt)+phi;
			 *(s.xd+k)=u-((float)((int) u));
		    }
		    chi_vec[j]=spline_pls(&s);
	       }
	       spline_srt(4, chi_vec, chi_idx);
	       *(phi_index+i)=chi_idx[0];
	       *(chi_sq+i)=chi_vec[chi_idx[0]];
	  }
	  spline_srt(n_freq, chi_sq, chi_index);
	  n_min=0;
	  n_max=MIN(NFITS, n_freq-2);
	  n_fits=0;
	  for (i=0; i < n_freq; i++)
	  {
	       j=*(chi_index+i);
	       if ((0 < j) && (j < n_freq-1))
	       {
		    x=*(chi_sq+j);
		    if (x >= 0.0)
		    {
			 if ((x <= *(chi_sq+j-1)) && (x < *(chi_sq+j+1)))
			 {
			      n_min++;
			      if (n_fits < n_max)
			      {
				   freq_index[n_fits++]=j;
			      }
			 }
		    }
	       }
	  }
	  for (i=0; i < n_fits; i++)
	  {
	       j=freq_index[i]-1;
	       chi_l=*(chi_sq+j++);
	       chi_m=*(chi_sq+j++);
	       chi_h=*(chi_sq+j--);
	       f=d_freq*((float) j);
	       freq_val[i]=f;
	       freq_chi[i]=chi_m;
	       df=-0.5*(chi_h-chi_l)/(chi_h+chi_l-2.0*chi_m);
	       f+=d_freq*df;
	       phi=((float) *(phi_index+j))/((float) 4*n_intervals);
	       for (j=0; j < nd; j++)
	       {
		    u=f*(*(s.xt+j)-*s.xt)+phi;
		    *(s.xd+j)=u-((float)((int) u));
	       }
	       chi_i=spline_pls(&s);
	       if (chi_i < chi_m)
	       {
		    freq_val[i]=f;
		    freq_chi[i]=chi_i;
	       }
	       freq_chi[i]/=((float)(nd-n_intervals));
	  }
	  spline_srt(n_fits, freq_chi, chi_index);
	  t_lapse=clock()-t_lapse;
	  printf("Number of chi square minima: %5i\n\n n  chi square "
		 " frequency\n\n", n_min);
	  for (i=0; i < MIN(15, n_fits); i++)
	  {
	       j=*(chi_index+i);
	       printf("%2i%12.6f%12.8f\n", i+1, freq_chi[j], freq_val[j]);
	  }
     }
     spline_end(&s);
     printf("\nTime elapsed: %10.3f seconds\n",
#ifdef __DECC
	    0.01*((double) t_lapse));
#else
     0.000001*((double) t_lapse));
#endif
     exit(0);
}
