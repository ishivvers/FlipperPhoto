/*****************************************************************************/
/*      include file for smoothing spline routines                           */
/*****************************************************************************/

/*   Define VAX_CPU if computer has Digital VAX integer word storage         */
/*   structure. (Most significant byte is last.)                             */
#define VAX_CPU 1

struct spline_str
{
     char    *alloc; /*  pointer to allocated array storage                  */
     int         nk; /*  number of independent B-spline functions            */
     int         nd; /*  number of data points                               */
     int       ierr; /*  return error code                                   */
     float     spar; /*  spline stiffness parameter                          */
     float     crit; /*  cross-validation score                              */
     float    chisq; /*  weighted sum of residual squares                    */
     float    ratio; /*  ratio of traces of the two derivative matrices      */
     float   lambda; /*  spline stifness constant                            */
     int      i_min; /*  minimum code (0 -> none, 1 -> minimum)              */
     float    x_min; /*  minimum location on knot interval                   */
     int      i_max; /*  maximum code (0 -> none, 1 -> maximum)              */
     float    x_max; /*  maximum location on knot interval                   */
     float    s_min; /*  minimum slope on entire range                       */
     float    s_max; /*  maximum slope on entire range                       */
     int      i_ifl; /*  inflection code (0 -> none, 1 -> inflection)        */
     float    x_ifl; /*  inflection location on knot interval                */
     int       i_lo; /*  knot interval for inflection point below min/max    */
     float     x_lo; /*  inflection location below min/max                   */
     int       i_hi; /*  knot interval for inflection point above min/max    */
     float     x_hi; /*  inflection location above min/max                   */
     float      *kn; /*  pointer to knot vector                   [nk+4]     */
     float      *cf; /*  pointer to B-spline coefficient vector   [nk]       */
     float      *ov; /*  pointer to observation vector            [nk]       */
     float      *om; /*  pointer to observation matrix            [nk][4]    */
     float      *cm; /*  pointer to curvature matrix              [nk][4]    */
     float      *dm; /*  pointer to derivative matrix             [nk][4]    */
     float      *ip; /*  pointer to inner product matrix          [nk][4]    */
     float      *xd; /*  pointer to x data vector                 [nd]       */
     float      *yd; /*  pointer to y data vector                 [nd]       */
     float      *wd; /*  pointer to w data vector                 [nd]       */
     float      *yc; /*  pointer to y calculated vector           [nd]       */
     float      *lv; /*  pointer to leverage vector               [nd]       */
     float      *xt; /*  pointer to time base data vector         [nd]       */
     float  *matrix; /*  pointer to periodic spline matrix        [ni][ni]   */
     double *base_a; /*  pointer to additional allocated memory              */
};

struct spline_dstr
{
     char    *alloc; /*  pointer to allocated array storage                  */
     int         nk; /*  number of independent B-spline functions            */
     int         nd; /*  number of data points                               */
     int       ierr; /*  return error code                                   */
     double    spar; /*  spline stiffness parameter                          */
     double    crit; /*  cross-validation score                              */
     double   chisq; /*  weighted sum of residual squares                    */
     double   ratio; /*  ratio of traces of the two derivative matrices      */
     double  lambda; /*  spline stifness constant                            */
     int      i_min; /*  minimum code (0 -> none, 1 -> minimum)              */
     double   x_min; /*  minimum location on knot interval                   */
     int      i_max; /*  maximum code (0 -> none, 1 -> maximum)              */
     double   x_max; /*  maximum location on knot interval                   */
     double   s_min; /*  minimum slope on entire range                       */
     double   s_max; /*  maximum slope on entire range                       */
     int      i_ifl; /*  inflection code (0 -> none, 1 -> inflection)        */
     double   x_ifl; /*  inflection location on knot interval                */
     int       i_lo; /*  knot interval for inflection point below min/max    */
     double    x_lo; /*  inflection location below min/max                   */
     int       i_hi; /*  knot interval for inflection point above min/max    */
     double    x_hi; /*  inflection location above min/max                   */
     double     *kn; /*  pointer to knot vector                   [nk+4]     */
     double     *cf; /*  pointer to B-spline coefficient vector   [nk]       */
     double     *ov; /*  pointer to observation vector            [nk]       */
     double     *om; /*  pointer to observation matrix            [nk][4]    */
     double     *cm; /*  pointer to curvature matrix              [nk][4]    */
     double     *dm; /*  pointer to derivative matrix             [nk][4]    */
     double     *ip; /*  pointer to inner product matrix          [nk][4]    */
     double     *xd; /*  pointer to x data vector                 [nd]       */
     double     *yd; /*  pointer to y data vector                 [nd]       */
     double     *wd; /*  pointer to w data vector                 [nd]       */
     double     *yc; /*  pointer to y calculated vector           [nd]       */
     double     *lv; /*  pointer to leverage vector               [nd]       */
     double     *xt; /*  pointer to time base data vector         [nd]       */
     double *matrix; /*  pointer to periodic spline matrix        [ni][ni]   */
     double *base_a; /*  pointer to additional allocated memory              */
};

#ifndef	MIN
#define	MIN(a,b) (((a)<(b))?(a):(b))
#endif

#ifndef	MAX
#define	MAX(a,b) (((a)>(b))?(a):(b))
#endif

#define ALIGN(A,B) ((B*)(((unsigned long)(A) + sizeof(B) -1) & -sizeof(B)))

#define M 3

#define I_BITS 4
#define F_BITS (8-I_BITS)
#define O_BITS 3
#define P_BITS 8
#define Q_BITS (P_BITS - O_BITS)
#define NI (1 << I_BITS)            /* number of spline intervals            */
#define NF (1 << F_BITS)            /* number of spline function values      */
#define NR (I_BITS - 1)             /* loop count for matrix reduction       */
#define OVER_SAMPLE (1 << O_BITS)   /* frequency oversampling ratio          */
#define FINE_SAMPLE (1 << Q_BITS)   /* frequency fine/coarse sweep ratio     */
#define I_MASK ((NI-1) << F_BITS)   /* mask for recovering interval bits     */
#define F_MASK (NF-1)               /* mask for recovering function bits     */
#define NI_NI (NI*NI)               /* size of regression matrix             */
#define LONG_INT 4294967296.0       /* 2^32 (used for phase initialization)  */
#define NFITS 60                    /* number of chi square minima tested    */

struct spline_srs
{
     struct spline_str       s; /* spline data structure                     */
     int                 nfreq; /* number of frequency samples               */
     float               dfreq; /* frequency sample interval                 */
     unsigned long int  *phase; /* period folding phase                 [nd] */
     unsigned long int *dphase; /* period folding phase increment       [nd] */
     unsigned char     *cphase; /* period folding 8-bit phase           [nd] */
     int            *chi_index; /* sort index to chi-square list     [nfreq] */
     int             *deg_free; /* number of degrees of freedom      [nfreq] */
     unsigned long   *fit_code; /* spline fit description code       [nfreq] */
     float              *chisq; /* chi square                        [nfreq] */
     float           *b_spline; /* spline value lookup table    [nd][NF][14] */
     float           **b_index; /* pointer to spline value table    [nd][NF] */
     float       **regress[NR]; /* pointer to regression sums   [2*NI-4][16] */
     float            *chi_vec; /* observation regression vector        [NI] */
     float            *chi_mat; /* least squares regression matrix  [NI][NI] */
     float                w_y2; /* weighted sum of square of observations    */
     int               chi_min; /* number of significant chi square minima   */
     int                 nfits; /* number of tested minima                   */
     int             *freq_iav; /* frequency index                   [NFITS] */
     int             *freq_har; /* maximum harmonic power            [NFITS] */
     int             *freq_ndf; /* number of degrees of freedom      [NFITS] */
     unsigned long   *freq_fit; /* spline fit description code       [NFITS] */
     float           *freq_chi; /* chi square                        [NFITS] */
     float           *freq_val; /* frequency value                   [NFITS] */
     float           *freq_flo; /* frequency lower bound             [NFITS] */
     float           *freq_fhi; /* frequency upper bound             [NFITS] */
};

struct spline_dsrs
{
     struct spline_dstr      s; /* spline data structure                     */
     int                 nfreq; /* number of frequency samples               */
     double              dfreq; /* frequency sample interval                 */
     unsigned long int  *phase; /* period folding phase                 [nd] */
     unsigned long int *dphase; /* period folding phase increment       [nd] */
     unsigned char     *cphase; /* period folding 8-bit phase           [nd] */
     int            *chi_index; /* sort index to chi-square list     [nfreq] */
     int             *deg_free; /* number of degrees of freedom      [nfreq] */
     unsigned long   *fit_code; /* spline fit description code       [nfreq] */
     double             *chisq; /* chi-square list                   [nfreq] */
     double          *b_spline; /* spline value lookup table    [nd][NF][14] */
     double          **b_index; /* pointer to spline value table    [nd][NF] */
     double      **regress[NR]; /* pointer to regression sums   [2*NI-4][16] */
     double           *chi_vec; /* observation regression vector        [NI] */
     double           *chi_mat; /* least squares regression matrix  [NI][NI] */
     double               w_y2; /* weighted sum of square of observations    */
     int               chi_min; /* number of significant chi square minima   */
     int                 nfits; /* number of tested minima                   */
     int             *freq_iav; /* frequency index                   [NFITS] */
     int             *freq_har; /* maximum harmonic power            [NFITS] */
     int             *freq_ndf; /* number of degrees of freedom      [NFITS] */
     unsigned long   *freq_fit; /* spline fit description code       [NFITS] */
     double          *freq_chi; /* chi square                        [NFITS] */
     double          *freq_val; /* frequency value                   [NFITS] */
     double          *freq_flo; /* frequency lower bound             [NFITS] */
     double          *freq_fhi; /* frequency upper bound             [NFITS] */
};

void spline_add(int n, float x, float vector_a[], float vector_b[]);
int spline_bas(float x, int nk, float knot[], float b_spline[M+1]);
void spline_csi(int i, float knot[], int n, float integral[2][4]);
struct spline_str spline_cst(int req_code, int nk, float knot[], int nd,
			     float xd[], float yd[]);
void spline_cur(int nk, float knot[], float curve_matrix[][M+1]);
void spline_cyc(float spar, float f, int nf, float spectrum[][2],
		struct spline_str *s);
void spline_cym(float spar, struct spline_str *s);
void spline_df0(int i, float knot[], float d0_b_spline[4][M+1]);
void spline_df1(int i, float knot[], float d1_b_spline[3][M+1]);
void spline_df2(int i, float knot[], float d2_b_spline[2][M+1]);
float spline_dot(int n, float vector_a[], float vector_b[]);
void spline_end(struct spline_str *s);
void spline_esr(struct spline_srs *s);
int spline_fnd(int icrit, float l_spar, float h_spar, struct spline_str *s);
void spline_har(struct spline_str *s, int nf, float spectrum[][2]);
struct spline_str spline_icy(int ni, int nd, float xd[], float yd[],
			     float wd[], int byte_alloc);
int spline_ifl(int i, struct spline_str *s);
struct spline_str spline_ini(int nk, float knot[], int nd, float xd[],
			     float yd[], float wd[]);
struct spline_str spline_int(int nd, float xd[], float yd[]);
int spline_inv(int m, int n, float matrix[]);
void spline_ipr(int nk, float deriv_matrix[][M+1], float iprod_matrix[][M+1]);
struct spline_srs spline_isr(float f_max, int nd, float xd[], float yd[],
			     float wd[]);
void spline_lse(int nk, float knot[], int nd, float xd[], float yd[],
		float wd[], float obsrv_vector[], float obsrv_matrix[][M+1]);
float spline_lvr(int icrit, float spar, struct spline_str *s);
int spline_miv(int n, float a[], float b[], int m[]);
int spline_mmx(int i, struct spline_str *s);
void spline_mul(int m, int n, float matrix[], float vector[]);
void spline_phs(float f, struct spline_srs *s);
float spline_pow(struct spline_str *s);
float spline_psp(float spar, struct spline_str *s);
int spline_rdc(int ni, unsigned long int diag_vals, float vector[], 
	       float matrix[]);
float spline_sag(struct spline_str *s);
void spline_slm(struct spline_str *s);
void spline_src(struct spline_srs *s);
void spline_srf(struct spline_srs *s);
int spline_sri(float matrix[]);
void spline_srl(struct spline_srs *s, int nfreq, int deg_free[],
		unsigned long int fit_code[], float chisq[]);
struct spline_str spline_srp(float f, struct spline_srs *s);
struct spline_str spline_srq(float f, struct spline_srs *s);
void spline_srt(int n, float x[], int index[]);
int spline_tbl(float x, int n, float vector[]);
float spline_twk(float chi_square, struct spline_str *s);
float spline_val(float x, struct spline_str *s);
float spline_vas(float x, struct spline_str *s);
void spline_dadd(int n, double x, double vector_a[], double vector_b[]);
int spline_dbas(double x, int nk, double knot[], double b_spline[M+1]);
void spline_dcsi(int i, double knot[], int n, double integral[2][4]);
struct spline_dstr spline_dcst(int req_code, int nk, double knot[], int nd,
			       double xd[], double yd[]);
void spline_dcur(int nk, double knot[], double curve_matrix[][M+1]);
void spline_dcyc(double spar, double f, int nf, double spectrum[][2],
		 struct spline_dstr *s);
void spline_dcym(double spar, struct spline_dstr *s);
void spline_ddf0(int i, double knot[], double d0_b_spline[4][M+1]);
void spline_ddf1(int i, double knot[], double d1_b_spline[3][M+1]);
void spline_ddf2(int i, double knot[], double d2_b_spline[2][M+1]);
double spline_ddot(int n, double vector_a[], double vector_b[]);
void spline_dend(struct spline_dstr *s);
void spline_desr(struct spline_dsrs *s);
int spline_dfnd(int icrit, double l_spar, double h_spar,
		struct spline_dstr *s);
void spline_dhar(struct spline_dstr *s, int nf, double spectrum[][2]);
struct spline_dstr spline_dicy(int ni, int nd, double xd[], double yd[],
			       double wd[], int byte_alloc);
int spline_difl(int i, struct spline_dstr *s);
struct spline_dstr spline_dini(int nk, double knot[], int nd, double xd[],
			       double yd[], double wd[]);
struct spline_dstr spline_dint(int nd, double xd[], double yd[]);
int spline_dinv(int m, int n, double matrix[]);
void spline_dipr(int nk, double deriv_matrix[][M+1],
		 double iprod_matrix[][M+1]);
struct spline_dsrs spline_disr(double f_max, int nd, double xd[], double yd[],
			       double wd[]);
void spline_dlse(int nk, double knot[], int nd, double xd[], double yd[],
		 double wd[], double obsrv_vector[],
		 double obsrv_matrix[][M+1]);
double spline_dlvr(int icrit, double spar, struct spline_dstr *s);
int spline_dmiv(int n, double a[], double b[], int m[]);
int spline_dmmx(int i, struct spline_dstr *s);
void spline_dmul(int m, int n, double matrix[], double vector[]);
void spline_dphs(double f, struct spline_dsrs *s);
double spline_dpow(struct spline_dstr *s);
double spline_dpsp(double spar, struct spline_dstr *s);
int spline_drdc(int ni, unsigned long int diag_vals, double vector[], 
		double matrix[]);
double spline_dsag(struct spline_dstr *s);
void spline_dslm(struct spline_dstr *s);
void spline_dsrc(struct spline_dsrs *s);
void spline_dsrf(struct spline_dsrs *s);
int spline_dsri(double matrix[]);
void spline_dsrl(struct spline_dsrs *s, int nfreq, int deg_free[],
		 unsigned long int fit_code[], double chisq[]);
struct spline_dstr spline_dsrp(double f, struct spline_dsrs *s);
struct spline_dstr spline_dsrq(double f, struct spline_dsrs *s);
void spline_dsrt(int n, double x[], int index[]);
int spline_dtbl(double x, int n, double vector[]);
double spline_dtwk(double chi_square, struct spline_dstr *s);
double spline_dval(double x, struct spline_dstr *s);
double spline_dvas(double x, struct spline_dstr *s);
