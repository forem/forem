# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'cpp.rb'

    class FreeFEM < Cpp
      title "FreeFEM"
      desc "The FreeFEM programming language (freefem.org)"

      tag 'freefem'
      aliases 'ff'
      filenames '*.edp', '*.idp'
      mimetypes 'text/x-ffhdr', 'text/x-ffsrc'

      # Override C/C++ ones (for example, `do` does not exists)
      def self.keywords
        @keywords ||= Set.new(%w(
          break catch continue else for if return try while
        ))
      end

      # Override C/C++ ones (for example, `double` does not exists)
      def self.keywords_type
        @keywords_type ||= Set.new(%w(
          bool border complex dmatrix fespace func gslspline ifstream int macro
          matrix mesh mesh3 mpiComm mpiGroup mpiRequest NewMacro EndMacro
          ofstream Pmmap problem Psemaphore real solve string varf
        ))
      end

      # Override C/C++ ones (totally different)
      def self.reserved
        @reserved ||= Set.new(%w(
          BDM1 BDM1Ortho Edge03d Edge13d Edge23d FEQF HCT P0 P03d P0Edge P1
          P13d P1b P1b3d P1bl P1bl3d P1dc P1Edge P1nc P2 P23d P2b P2BR P2dc
          P2Edge P2h P2Morley P2pnc P3 P3dc P3Edge P4 P4dc P4Edge P5Edge RT0
          RT03d RT0Ortho RT1 RT1Ortho RT2 RT2Ortho

          qf1pE qf1pElump qf1pT qf1pTlump qfV1 qfV1lump qf2pE qf2pT qf2pT4P1
          qfV2 qf3pE qf4pE qf5pE qf5pT qfV5 qf7pT qf9pT qfnbpE

          ARGV append area be binary BoundaryEdge bordermeasure CG Cholesky cin
          cout Crout default diag edgeOrientation endl FILE fixed GMRES good
          hTriangle im imax imin InternalEdge l1 l2 label lenEdge length LINE
          linfty LU m max measure min mpiAnySource mpiBAND mpiBXOR mpiCommWorld
          mpiLAND mpiLOR mpiLXOR mpiMAX mpiMIN mpiPROD mpirank mpisize mpiSUM
          mpiUndefined n N nbe ndof ndofK noshowbase noshowpos notaregion nt
          nTonEdge nuEdge nuTriangle nv P pi precision quantile re region
          scientific searchMethod setw showbase showpos sparsesolver sum tellp
          true UMFPACK unused whoinElement verbosity version volume x y z
        ))
      end

      def self.builtins
        @builtins ||= Set.new(%w(
          abs acos acosh adaptmesh adj AffineCG AffineGMRES arg asin asinh
          assert atan atan2 atanh atof atoi BFGS broadcast buildlayers
          buildmesh ceil chi complexEigenValue copysign change checkmovemesh
          clock cmaes conj convect cos cosh cube d dd dfft diffnp diffpos
          dimKrylov dist dumptable dx dxx dxy dxz dy dyx dyy dyz dz dzx dzy dzz
          EigenValue emptymesh erf erfc exec exit exp fdim ffind find floor
          flush fmax fmin fmod freeyams getARGV getline gmshload gmshload3
          gslcdfugaussianP gslcdfugaussianQ gslcdfugaussianPinv
          gslcdfugaussianQinv gslcdfgaussianP gslcdfgaussianQ
          gslcdfgaussianPinv gslcdfgaussianQinv gslcdfgammaP gslcdfgammaQ
          gslcdfgammaPinv gslcdfgammaQinv gslcdfcauchyP gslcdfcauchyQ
          gslcdfcauchyPinv gslcdfcauchyQinv gslcdflaplaceP gslcdflaplaceQ
          gslcdflaplacePinv gslcdflaplaceQinv gslcdfrayleighP gslcdfrayleighQ
          gslcdfrayleighPinv gslcdfrayleighQinv gslcdfchisqP gslcdfchisqQ
          gslcdfchisqPinv gslcdfchisqQinv gslcdfexponentialP gslcdfexponentialQ
          gslcdfexponentialPinv gslcdfexponentialQinv gslcdfexppowP
          gslcdfexppowQ gslcdftdistP gslcdftdistQ gslcdftdistPinv
          gslcdftdistQinv gslcdffdistP gslcdffdistQ gslcdffdistPinv
          gslcdffdistQinv gslcdfbetaP gslcdfbetaQ gslcdfbetaPinv gslcdfbetaQinv
          gslcdfflatP gslcdfflatQ gslcdfflatPinv gslcdfflatQinv
          gslcdflognormalP gslcdflognormalQ gslcdflognormalPinv
          gslcdflognormalQinv gslcdfgumbel1P gslcdfgumbel1Q gslcdfgumbel1Pinv
          gslcdfgumbel1Qinv gslcdfgumbel2P gslcdfgumbel2Q gslcdfgumbel2Pinv
          gslcdfgumbel2Qinv gslcdfweibullP gslcdfweibullQ gslcdfweibullPinv
          gslcdfweibullQinv gslcdfparetoP gslcdfparetoQ gslcdfparetoPinv
          gslcdfparetoQinv gslcdflogisticP gslcdflogisticQ gslcdflogisticPinv
          gslcdflogisticQinv gslcdfbinomialP gslcdfbinomialQ gslcdfpoissonP
          gslcdfpoissonQ gslcdfgeometricP gslcdfgeometricQ
          gslcdfnegativebinomialP gslcdfnegativebinomialQ gslcdfpascalP
          gslcdfpascalQ gslinterpakima gslinterpakimaperiodic
          gslinterpcsplineperiodic gslinterpcspline gslinterpsteffen
          gslinterplinear gslinterppolynomial gslranbernoullipdf gslranbeta
          gslranbetapdf gslranbinomialpdf gslranexponential
          gslranexponentialpdf gslranexppow gslranexppowpdf gslrancauchy
          gslrancauchypdf gslranchisq gslranchisqpdf gslranerlang
          gslranerlangpdf gslranfdist gslranfdistpdf gslranflat gslranflatpdf
          gslrangamma gslrangammaint gslrangammapdf gslrangammamt
          gslrangammaknuth gslrangaussian gslrangaussianratiomethod
          gslrangaussianziggurat gslrangaussianpdf gslranugaussian
          gslranugaussianratiomethod gslranugaussianpdf gslrangaussiantail
          gslrangaussiantailpdf gslranugaussiantail gslranugaussiantailpdf
          gslranlandau gslranlandaupdf gslrangeometricpdf gslrangumbel1
          gslrangumbel1pdf gslrangumbel2 gslrangumbel2pdf gslranlogistic
          gslranlogisticpdf gslranlognormal gslranlognormalpdf
          gslranlogarithmicpdf gslrannegativebinomialpdf gslranpascalpdf
          gslranpareto gslranparetopdf gslranpoissonpdf gslranrayleigh
          gslranrayleighpdf gslranrayleightail gslranrayleightailpdf
          gslrantdist gslrantdistpdf gslranlaplace gslranlaplacepdf gslranlevy
          gslranweibull gslranweibullpdf gslsfairyAi gslsfairyBi
          gslsfairyAiscaled gslsfairyBiscaled gslsfairyAideriv gslsfairyBideriv
          gslsfairyAiderivscaled gslsfairyBiderivscaled gslsfairyzeroAi
          gslsfairyzeroBi gslsfairyzeroAideriv gslsfairyzeroBideriv
          gslsfbesselJ0 gslsfbesselJ1 gslsfbesselJn gslsfbesselY0 gslsfbesselY1
          gslsfbesselYn gslsfbesselI0 gslsfbesselI1 gslsfbesselIn
          gslsfbesselI0scaled gslsfbesselI1scaled gslsfbesselInscaled
          gslsfbesselK0 gslsfbesselK1 gslsfbesselKn gslsfbesselK0scaled
          gslsfbesselK1scaled gslsfbesselKnscaled gslsfbesselj0 gslsfbesselj1
          gslsfbesselj2 gslsfbesseljl gslsfbessely0 gslsfbessely1 gslsfbessely2
          gslsfbesselyl gslsfbesseli0scaled gslsfbesseli1scaled
          gslsfbesseli2scaled gslsfbesselilscaled gslsfbesselk0scaled
          gslsfbesselk1scaled gslsfbesselk2scaled gslsfbesselklscaled
          gslsfbesselJnu gslsfbesselYnu gslsfbesselInuscaled gslsfbesselInu
          gslsfbesselKnuscaled gslsfbesselKnu gslsfbessellnKnu
          gslsfbesselzeroJ0 gslsfbesselzeroJ1 gslsfbesselzeroJnu gslsfclausen
          gslsfhydrogenicR1 gslsfdawson gslsfdebye1 gslsfdebye2 gslsfdebye3
          gslsfdebye4 gslsfdebye5 gslsfdebye6 gslsfdilog gslsfmultiply
          gslsfellintKcomp gslsfellintEcomp gslsfellintPcomp gslsfellintDcomp
          gslsfellintF gslsfellintE gslsfellintRC gslsferfc gslsflogerfc
          gslsferf gslsferfZ gslsferfQ gslsfhazard gslsfexp gslsfexpmult
          gslsfexpm1 gslsfexprel gslsfexprel2 gslsfexpreln gslsfexpintE1
          gslsfexpintE2 gslsfexpintEn gslsfexpintE1scaled gslsfexpintE2scaled
          gslsfexpintEnscaled gslsfexpintEi gslsfexpintEiscaled gslsfShi
          gslsfChi gslsfexpint3 gslsfSi gslsfCi gslsfatanint gslsffermidiracm1
          gslsffermidirac0 gslsffermidirac1 gslsffermidirac2 gslsffermidiracint
          gslsffermidiracmhalf gslsffermidirachalf gslsffermidirac3half
          gslsffermidiracinc0 gslsflngamma gslsfgamma gslsfgammastar
          gslsfgammainv gslsftaylorcoeff gslsffact gslsfdoublefact gslsflnfact
          gslsflndoublefact gslsflnchoose gslsfchoose gslsflnpoch gslsfpoch
          gslsfpochrel gslsfgammaincQ gslsfgammaincP gslsfgammainc gslsflnbeta
          gslsfbeta gslsfbetainc gslsfgegenpoly1 gslsfgegenpoly2
          gslsfgegenpoly3 gslsfgegenpolyn gslsfhyperg0F1 gslsfhyperg1F1int
          gslsfhyperg1F1 gslsfhypergUint gslsfhypergU gslsfhyperg2F0
          gslsflaguerre1 gslsflaguerre2 gslsflaguerre3 gslsflaguerren
          gslsflambertW0 gslsflambertWm1 gslsflegendrePl gslsflegendreP1
          gslsflegendreP2 gslsflegendreP3 gslsflegendreQ0 gslsflegendreQ1
          gslsflegendreQl gslsflegendrePlm gslsflegendresphPlm
          gslsflegendrearraysize gslsfconicalPhalf gslsfconicalPmhalf
          gslsfconicalP0 gslsfconicalP1 gslsfconicalPsphreg gslsfconicalPcylreg
          gslsflegendreH3d0 gslsflegendreH3d1 gslsflegendreH3d gslsflog
          gslsflogabs gslsflog1plusx gslsflog1plusxmx gslsfpowint gslsfpsiint
          gslsfpsi gslsfpsi1piy gslsfpsi1int gslsfpsi1 gslsfpsin
          gslsfsynchrotron1 gslsfsynchrotron2 gslsftransport2 gslsftransport3
          gslsftransport4 gslsftransport5 gslsfsin gslsfcos gslsfhypot
          gslsfsinc gslsflnsinh gslsflncosh gslsfanglerestrictsymm
          gslsfanglerestrictpos gslsfzetaint gslsfzeta gslsfzetam1
          gslsfzetam1int gslsfhzeta gslsfetaint gslsfeta imag int1d int2d int3d
          intalledges intallfaces interpolate invdiff invdiffnp invdiffpos
          Isend isInf isNaN isoline Irecv j0 j1 jn jump lgamma LinearCG
          LinearGMRES log log10 lrint lround max mean medit min mmg3d movemesh
          movemesh23 mpiAlltoall mpiAlltoallv mpiAllgather mpiAllgatherv
          mpiAllReduce mpiBarrier mpiGather mpiGatherv mpiRank mpiReduce
          mpiScatter mpiScatterv mpiSize mpiWait mpiWaitAny mpiWtick mpiWtime
          mshmet NLCG on plot polar Post pow processor processorblock
          projection randinit randint31 randint32 random randreal1 randreal2
          randreal3 randres53 Read readmesh readmesh3 Recv rfind rint round
          savemesh savesol savevtk seekg Sent set sign signbit sin sinh sort
          splitComm splitmesh sqrt square srandom srandomdev Stringification
          swap system tan tanh tellg tetg tetgconvexhull tetgreconstruction
          tetgtransfo tgamma triangulate trunc Wait Write y0 y1 yn
        ))
      end

      def self.attributes
        @builtinsParameters ||= Set.new(%w(
          A A1 abserror absolute aniso aspectratio B B1 bb beginend bin
          boundary bw close cmm coef composante cutoff datafilename dataname
          dim distmax displacement doptions dparams eps err errg facemerge
          facetcl factorize file fill fixedborder flabel flags floatmesh
          floatsol fregion gradation grey hmax hmin holelist hsv init inquire
          inside IsMetric iso ivalue keepbackvertices label labeldown labelmid
          labelup levelset loptions lparams maxit maxsubdiv meditff mem memory
          metric mode nbarrow nbiso nbiter nbjacoby nboffacetcl nbofholes
          nbofregions nbregul nbsmooth nbvx ncv nev nomeshgeneration
          normalization omega op optimize option options order orientation
          periodic power precon prev ps ptmerge qfe qforder qft qfV ratio
          rawvector reffacelow reffacemid reffaceup refnum reftet reftri region
          regionlist renumv rescaling ridgeangle save sigma sizeofvolume
          smoothing solver sparams split splitin2 splitpbedge stop strategy
          swap switch sym t tgv thetamax tol tolpivot tolpivotsym transfo U2Vc
          value varrow vector veps viso wait width withsurfacemesh WindowIndex
          which zbound
        ))
      end

      id = /[a-z_]\w*/i

      state :expr_bol do
        mixin :inline_whitespace

        rule %r/include/, Comment::Preproc, :macro
        rule %r/load/, Comment::Preproc, :macro
        rule %r/ENDIFMACRO/, Comment::Preproc, :macro
        rule %r/IFMACRO/, Comment::Preproc, :macro

        rule(//) { pop! }
      end

      state :statements do
        mixin :whitespace
        rule %r/(u8|u|U|L)?"/, Str, :string
        rule %r((u8|u|U|L)?'(\\.|\\[0-7]{1,3}|\\x[a-f0-9]{1,2}|[^\\'\n])')i, Str::Char
        rule %r((\d+[.]\d*|[.]?\d+)e[+-]?\d+[lu]*)i, Num::Float
        rule %r(\d+e[+-]?\d+[lu]*)i, Num::Float
        rule %r/0x[0-9a-f]+[lu]*/i, Num::Hex
        rule %r/0[0-7]+[lu]*/i, Num::Oct
        rule %r/\d+[lu]*/i, Num::Integer
        rule %r(\*/), Error
        rule %r([~!%^&*+=\|?:<>/-]), Operator
        rule %r/'/, Operator
        rule %r/[()\[\],.;]/, Punctuation
        rule %r/\bcase\b/, Keyword, :case
        rule %r/(?:true|false|NaN)\b/, Name::Builtin
        rule id do |m|
          name = m[0]

          if self.class.keywords.include? name
            token Keyword
          elsif self.class.keywords_type.include? name
            token Keyword::Type
          elsif self.class.reserved.include? name
            token Keyword::Reserved
          elsif self.class.builtins.include? name
            token Name::Builtin
          elsif self.class.attributes.include? name
            token Name::Attribute
          else
            token Name
          end
        end
      end
    end
  end
end
