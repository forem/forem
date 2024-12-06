# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class IgorPro < RegexLexer
      tag 'igorpro'
      filenames '*.ipf'
      mimetypes 'text/x-igorpro'

      title "IgorPro"
      desc "WaveMetrics Igor Pro"

      def self.keywords
        @keywords ||= Set.new %w(
          structure endstructure
          threadsafe static
          macro proc window menu function end
          if else elseif endif switch strswitch endswitch
          break return continue
          for endfor do while
          case default
          try catch endtry
          abortonrte
        )
      end

      def self.preprocessor
        @preprocessor ||= Set.new %w(
          pragma include
          define ifdef ifndef undef
          if elif else endif
        )
      end

      def self.igorDeclarations
        @igorDeclarations ||= Set.new %w(
          variable string wave strconstant constant
          nvar svar dfref funcref struct
          char uchar int16 uint16 int32 uint32 int64 uint64 float double
        )
      end

      def self.igorConstants
        @igorConstants ||= Set.new %w(
          nan inf
        )
      end

      def self.igorFunction
        @igorFunction ||= Set.new %w(
          AddListItem AiryA AiryAD AiryB AiryBD AnnotationInfo
          AnnotationList AxisInfo AxisList AxisValFromPixel
          AxonTelegraphAGetDataNum AxonTelegraphAGetDataString
          AxonTelegraphAGetDataStruct AxonTelegraphGetDataNum
          AxonTelegraphGetDataString AxonTelegraphGetDataStruct
          AxonTelegraphGetTimeoutMs AxonTelegraphSetTimeoutMs
          Base64Decode Base64Encode Besseli Besselj Besselk
          Bessely BinarySearch BinarySearchInterp CTabList
          CaptureHistory CaptureHistoryStart CheckName
          ChildWindowList CleanupName ContourInfo ContourNameList
          ContourNameToWaveRef ContourZ ControlNameList
          ConvertTextEncoding CountObjects CountObjectsDFR
          CreationDate CsrInfo CsrWave CsrWaveRef CsrXWave
          CsrXWaveRef DataFolderDir DataFolderExists
          DataFolderRefStatus DataFolderRefsEqual DateToJulian
          Dawson DimDelta DimOffset DimSize Faddeeva FetchURL
          FindDimLabel FindListItem FontList FontSizeHeight
          FontSizeStringWidth FresnelCos FresnelSin FuncRefInfo
          FunctionInfo FunctionList FunctionPath
          GISGetAllFileFormats GISSRefsAreEqual Gauss Gauss1D
          Gauss2D GetBrowserLine GetBrowserSelection
          GetDataFolder GetDataFolderDFR GetDefaultFont
          GetDefaultFontSize GetDefaultFontStyle GetDimLabel
          GetEnvironmentVariable GetErrMessage GetFormula
          GetIndependentModuleName GetIndexedObjName
          GetIndexedObjNameDFR GetKeyState GetRTErrMessage
          GetRTError GetRTLocInfo GetRTLocation GetRTStackInfo
          GetScrapText GetUserData GetWavesDataFolder
          GetWavesDataFolderDFR GizmoInfo GizmoScale GrepList
          GrepString GuideInfo GuideNameList HDF5AttributeInfo
          HDF5DatasetInfo HDF5LibraryInfo HDF5TypeInfo Hash
          HyperG0F1 HyperG1F1 HyperG2F1 HyperGNoise HyperGPFQ
          IgorInfo IgorVersion ImageInfo ImageNameList
          ImageNameToWaveRef IndependentModuleList IndexToScale
          IndexedDir IndexedFile Inf Integrate1D Interp2D
          Interp3D ItemsInList JacobiCn JacobiSn JulianToDate
          Laguerre LaguerreA LaguerreGauss LambertW LayoutInfo
          LegendreA ListMatch ListToTextWave ListToWaveRefWave
          LowerStr MCC_AutoBridgeBal MCC_AutoFastComp
          MCC_AutoPipetteOffset MCC_AutoSlowComp
          MCC_AutoWholeCellComp MCC_GetBridgeBalEnable
          MCC_GetBridgeBalResist MCC_GetFastCompCap
          MCC_GetFastCompTau MCC_GetHolding MCC_GetHoldingEnable
          MCC_GetMode MCC_GetNeutralizationCap
          MCC_GetNeutralizationEnable MCC_GetOscKillerEnable
          MCC_GetPipetteOffset MCC_GetPrimarySignalGain
          MCC_GetPrimarySignalHPF MCC_GetPrimarySignalLPF
          MCC_GetRsCompBandwidth MCC_GetRsCompCorrection
          MCC_GetRsCompEnable MCC_GetRsCompPrediction
          MCC_GetSecondarySignalGain MCC_GetSecondarySignalLPF
          MCC_GetSlowCompCap MCC_GetSlowCompTau
          MCC_GetSlowCompTauX20Enable MCC_GetSlowCurrentInjEnable
          MCC_GetSlowCurrentInjLevel
          MCC_GetSlowCurrentInjSetlTime MCC_GetWholeCellCompCap
          MCC_GetWholeCellCompEnable MCC_GetWholeCellCompResist
          MCC_SelectMultiClamp700B MCC_SetBridgeBalEnable
          MCC_SetBridgeBalResist MCC_SetFastCompCap
          MCC_SetFastCompTau MCC_SetHolding MCC_SetHoldingEnable
          MCC_SetMode MCC_SetNeutralizationCap
          MCC_SetNeutralizationEnable MCC_SetOscKillerEnable
          MCC_SetPipetteOffset MCC_SetPrimarySignalGain
          MCC_SetPrimarySignalHPF MCC_SetPrimarySignalLPF
          MCC_SetRsCompBandwidth MCC_SetRsCompCorrection
          MCC_SetRsCompEnable MCC_SetRsCompPrediction
          MCC_SetSecondarySignalGain MCC_SetSecondarySignalLPF
          MCC_SetSlowCompCap MCC_SetSlowCompTau
          MCC_SetSlowCompTauX20Enable MCC_SetSlowCurrentInjEnable
          MCC_SetSlowCurrentInjLevel
          MCC_SetSlowCurrentInjSetlTime MCC_SetTimeoutMs
          MCC_SetWholeCellCompCap MCC_SetWholeCellCompEnable
          MCC_SetWholeCellCompResist MPFXEMGPeak
          MPFXExpConvExpPeak MPFXGaussPeak MPFXLorenzianPeak
          MPFXVoigtPeak MacroList MandelbrotPoint MarcumQ
          MatrixCondition MatrixDet MatrixDot MatrixRank
          MatrixTrace ModDate NVAR_Exists NaN NameOfWave
          NewFreeDataFolder NewFreeWave NormalizeUnicode
          NumVarOrDefault NumberByKey OperationList PICTInfo
          PICTList PadString PanelResolution ParamIsDefault
          ParseFilePath PathList Pi PixelFromAxisVal PolygonArea
          PossiblyQuoteName ProcedureText RemoveByKey
          RemoveEnding RemoveFromList RemoveListItem
          ReplaceNumberByKey ReplaceString ReplaceStringByKey
          SQL2DBinaryWaveToTextWave SQLAllocHandle SQLAllocStmt
          SQLBinaryWavesToTextWave SQLBindCol SQLBindParameter
          SQLBrowseConnect SQLBulkOperations SQLCancel
          SQLCloseCursor SQLColAttributeNum SQLColAttributeStr
          SQLColumnPrivileges SQLColumns SQLConnect
          SQLDataSources SQLDescribeCol SQLDescribeParam
          SQLDisconnect SQLDriverConnect SQLDrivers SQLEndTran
          SQLError SQLExecDirect SQLExecute SQLFetch
          SQLFetchScroll SQLForeignKeys SQLFreeConnect SQLFreeEnv
          SQLFreeHandle SQLFreeStmt SQLGetConnectAttrNum
          SQLGetConnectAttrStr SQLGetCursorName SQLGetDataNum
          SQLGetDataStr SQLGetDescFieldNum SQLGetDescFieldStr
          SQLGetDescRec SQLGetDiagFieldNum SQLGetDiagFieldStr
          SQLGetDiagRec SQLGetEnvAttrNum SQLGetEnvAttrStr
          SQLGetFunctions SQLGetInfoNum SQLGetInfoStr
          SQLGetStmtAttrNum SQLGetStmtAttrStr SQLGetTypeInfo
          SQLMoreResults SQLNativeSql SQLNumParams
          SQLNumResultCols SQLNumResultRowsIfKnown
          SQLNumRowsFetched SQLParamData SQLPrepare
          SQLPrimaryKeys SQLProcedureColumns SQLProcedures
          SQLPutData SQLReinitialize SQLRowCount
          SQLSetConnectAttrNum SQLSetConnectAttrStr
          SQLSetCursorName SQLSetDescFieldNum SQLSetDescFieldStr
          SQLSetDescRec SQLSetEnvAttrNum SQLSetEnvAttrStr
          SQLSetPos SQLSetStmtAttrNum SQLSetStmtAttrStr
          SQLSpecialColumns SQLStatistics SQLTablePrivileges
          SQLTables SQLTextWaveTo2DBinaryWave
          SQLTextWaveToBinaryWaves SQLUpdateBoundValues
          SQLXOPCheckState SVAR_Exists ScreenResolution Secs2Date
          Secs2Time SelectNumber SelectString
          SetEnvironmentVariable SortList SpecialCharacterInfo
          SpecialCharacterList SpecialDirPath SphericalBessJ
          SphericalBessJD SphericalBessY SphericalBessYD
          SphericalHarmonics StartMSTimer StatsBetaCDF
          StatsBetaPDF StatsBinomialCDF StatsBinomialPDF
          StatsCMSSDCDF StatsCauchyCDF StatsCauchyPDF StatsChiCDF
          StatsChiPDF StatsCorrelation StatsDExpCDF StatsDExpPDF
          StatsEValueCDF StatsEValuePDF StatsErlangCDF
          StatsErlangPDF StatsErrorPDF StatsExpCDF StatsExpPDF
          StatsFCDF StatsFPDF StatsFriedmanCDF StatsGEVCDF
          StatsGEVPDF StatsGammaCDF StatsGammaPDF
          StatsGeometricCDF StatsGeometricPDF StatsHyperGCDF
          StatsHyperGPDF StatsInvBetaCDF StatsInvBinomialCDF
          StatsInvCMSSDCDF StatsInvCauchyCDF StatsInvChiCDF
          StatsInvDExpCDF StatsInvEValueCDF StatsInvExpCDF
          StatsInvFCDF StatsInvFriedmanCDF StatsInvGammaCDF
          StatsInvGeometricCDF StatsInvKuiperCDF
          StatsInvLogNormalCDF StatsInvLogisticCDF
          StatsInvMaxwellCDF StatsInvMooreCDF
          StatsInvNBinomialCDF StatsInvNCChiCDF StatsInvNCFCDF
          StatsInvNormalCDF StatsInvParetoCDF StatsInvPoissonCDF
          StatsInvPowerCDF StatsInvQCDF StatsInvQpCDF
          StatsInvRayleighCDF StatsInvRectangularCDF
          StatsInvSpearmanCDF StatsInvStudentCDF
          StatsInvTopDownCDF StatsInvTriangularCDF
          StatsInvUsquaredCDF StatsInvVonMisesCDF
          StatsInvWeibullCDF StatsKuiperCDF StatsLogNormalCDF
          StatsLogNormalPDF StatsLogisticCDF StatsLogisticPDF
          StatsMaxwellCDF StatsMaxwellPDF StatsMedian
          StatsMooreCDF StatsNBinomialCDF StatsNBinomialPDF
          StatsNCChiCDF StatsNCChiPDF StatsNCFCDF StatsNCFPDF
          StatsNCTCDF StatsNCTPDF StatsNormalCDF StatsNormalPDF
          StatsParetoCDF StatsParetoPDF StatsPermute
          StatsPoissonCDF StatsPoissonPDF StatsPowerCDF
          StatsPowerNoise StatsPowerPDF StatsQCDF StatsQpCDF
          StatsRayleighCDF StatsRayleighPDF StatsRectangularCDF
          StatsRectangularPDF StatsRunsCDF StatsSpearmanRhoCDF
          StatsStudentCDF StatsStudentPDF StatsTopDownCDF
          StatsTriangularCDF StatsTriangularPDF StatsTrimmedMean
          StatsUSquaredCDF StatsVonMisesCDF StatsVonMisesNoise
          StatsVonMisesPDF StatsWaldCDF StatsWaldPDF
          StatsWeibullCDF StatsWeibullPDF StopMSTimer
          StrVarOrDefault StringByKey StringFromList StringList
          StudentA StudentT TDMAddChannel TDMAddGroup
          TDMAppendDataValues TDMAppendDataValuesTime
          TDMChannelPropertyExists TDMCloseChannel TDMCloseFile
          TDMCloseGroup TDMCreateChannelProperty TDMCreateFile
          TDMCreateFileProperty TDMCreateGroupProperty
          TDMFilePropertyExists TDMGetChannelPropertyNames
          TDMGetChannelPropertyNum TDMGetChannelPropertyStr
          TDMGetChannelPropertyTime TDMGetChannelPropertyType
          TDMGetChannelStringPropertyLen TDMGetChannels
          TDMGetDataType TDMGetDataValues TDMGetDataValuesTime
          TDMGetFilePropertyNames TDMGetFilePropertyNum
          TDMGetFilePropertyStr TDMGetFilePropertyTime
          TDMGetFilePropertyType TDMGetFileStringPropertyLen
          TDMGetGroupPropertyNames TDMGetGroupPropertyNum
          TDMGetGroupPropertyStr TDMGetGroupPropertyTime
          TDMGetGroupPropertyType TDMGetGroupStringPropertyLen
          TDMGetGroups TDMGetLibraryErrorDescription
          TDMGetNumChannelProperties TDMGetNumChannels
          TDMGetNumDataValues TDMGetNumFileProperties
          TDMGetNumGroupProperties TDMGetNumGroups
          TDMGroupPropertyExists TDMOpenFile TDMOpenFileEx
          TDMRemoveChannel TDMRemoveGroup TDMReplaceDataValues
          TDMReplaceDataValuesTime TDMSaveFile
          TDMSetChannelPropertyNum TDMSetChannelPropertyStr
          TDMSetChannelPropertyTime TDMSetDataValues
          TDMSetDataValuesTime TDMSetFilePropertyNum
          TDMSetFilePropertyStr TDMSetFilePropertyTime
          TDMSetGroupPropertyNum TDMSetGroupPropertyStr
          TDMSetGroupPropertyTime TableInfo TagVal TagWaveRef
          TextEncodingCode TextEncodingName TextFile
          ThreadGroupCreate ThreadGroupGetDF ThreadGroupGetDFR
          ThreadGroupRelease ThreadGroupWait ThreadProcessorCount
          ThreadReturnValue TraceFromPixel TraceInfo
          TraceNameList TraceNameToWaveRef TrimString URLDecode
          URLEncode UnPadString UniqueName
          UnsetEnvironmentVariable UpperStr VariableList Variance
          VoigtFunc VoigtPeak WaveCRC WaveDims WaveExists
          WaveHash WaveInfo WaveList WaveMax WaveMin WaveName
          WaveRefIndexed WaveRefIndexedDFR WaveRefWaveToList
          WaveRefsEqual WaveTextEncoding WaveType WaveUnits
          WhichListItem WinList WinName WinRecreation WinType
          XWaveName XWaveRefFromTrace ZernikeR abs acos acosh
          alog area areaXY asin asinh atan atan2 atanh beta betai
          binomial binomialNoise binomialln cabs ceil cequal
          char2num chebyshev chebyshevU cmplx cmpstr conj cos
          cosIntegral cosh cot coth cpowi csc csch date date2secs
          datetime defined deltax digamma dilogarithm ei enoise
          equalWaves erf erfc erfcw exists exp expInt
          expIntegralE1 expNoise fDAQmx_AI_GetReader
          fDAQmx_AO_UpdateOutputs fDAQmx_CTR_Finished
          fDAQmx_CTR_IsFinished fDAQmx_CTR_IsPulseFinished
          fDAQmx_CTR_ReadCounter fDAQmx_CTR_ReadWithOptions
          fDAQmx_CTR_SetPulseFrequency fDAQmx_CTR_Start
          fDAQmx_ConnectTerminals fDAQmx_DIO_Finished
          fDAQmx_DIO_PortWidth fDAQmx_DIO_Read fDAQmx_DIO_Write
          fDAQmx_DeviceNames fDAQmx_DisconnectTerminals
          fDAQmx_ErrorString fDAQmx_ExternalCalDate
          fDAQmx_NumAnalogInputs fDAQmx_NumAnalogOutputs
          fDAQmx_NumCounters fDAQmx_NumDIOPorts fDAQmx_ReadChan
          fDAQmx_ReadNamedChan fDAQmx_ResetDevice
          fDAQmx_ScanGetAvailable fDAQmx_ScanGetNextIndex
          fDAQmx_ScanStart fDAQmx_ScanStop fDAQmx_ScanWait
          fDAQmx_ScanWaitWithTimeout fDAQmx_SelfCalDate
          fDAQmx_SelfCalibration fDAQmx_WF_IsFinished
          fDAQmx_WF_WaitUntilFinished fDAQmx_WaveformStart
          fDAQmx_WaveformStop fDAQmx_WriteChan factorial fakedata
          faverage faverageXY floor gamma gammaEuler gammaInc
          gammaNoise gammln gammp gammq gcd gnoise hcsr hermite
          hermiteGauss imag interp inverseERF inverseERFC leftx
          limit ln log logNormalNoise lorentzianNoise magsqr max
          mean median min mod norm note num2char num2istr num2str
          numpnts numtype p2rect pcsr pnt2x poissonNoise poly
          poly2D qcsr r2polar real rightx round sawtooth
          scaleToIndex sec sech sign sin sinIntegral sinc sinh
          sqrt str2num stringCRC stringmatch strlen strsearch sum
          tan tango_close_device tango_command_inout
          tango_compute_image_proj tango_get_dev_attr_list
          tango_get_dev_black_box tango_get_dev_cmd_list
          tango_get_dev_status tango_get_dev_timeout
          tango_get_error_stack tango_open_device
          tango_ping_device tango_read_attribute
          tango_read_attributes tango_reload_dev_interface
          tango_resume_attr_monitor tango_set_attr_monitor_period
          tango_set_dev_timeout tango_start_attr_monitor
          tango_stop_attr_monitor tango_suspend_attr_monitor
          tango_write_attribute tango_write_attributes tanh ticks
          time trunc vcsr viAssertIntrSignal viAssertTrigger
          viAssertUtilSignal viClear viClose viDisableEvent
          viDiscardEvents viEnableEvent viFindNext viFindRsrc
          viGetAttribute viGetAttributeString viGpibCommand
          viGpibControlATN viGpibControlREN viGpibPassControl
          viGpibSendIFC viIn16 viIn32 viIn8 viLock viMapAddress
          viMapTrigger viMemAlloc viMemFree viMoveIn16 viMoveIn32
          viMoveIn8 viMoveOut16 viMoveOut32 viMoveOut8 viOpen
          viOpenDefaultRM viOut16 viOut32 viOut8 viPeek16
          viPeek32 viPeek8 viPoke16 viPoke32 viPoke8 viRead
          viReadSTB viSetAttribute viSetAttributeString
          viStatusDesc viTerminate viUnlock viUnmapAddress
          viUnmapTrigger viUsbControlIn viUsbControlOut
          viVxiCommandQuery viWaitOnEvent viWrite wnoise x2pnt
          xcsr zcsr zeromq_client_connect zeromq_client_connect
          zeromq_client_recv zeromq_client_recv
          zeromq_client_send zeromq_client_send
          zeromq_handler_start zeromq_handler_start
          zeromq_handler_stop zeromq_handler_stop
          zeromq_server_bind zeromq_server_bind
          zeromq_server_recv zeromq_server_recv
          zeromq_server_send zeromq_server_send zeromq_set
          zeromq_set zeromq_stop zeromq_stop
          zeromq_test_callfunction zeromq_test_callfunction
          zeromq_test_serializeWave zeromq_test_serializeWave
          zeta
        )
      end

      def self.igorOperation
        @igorOperation ||= Set.new %w(
          APMath Abort AddFIFOData AddFIFOVectData AddMovieAudio
          AddMovieFrame AddWavesToBoxPlot AddWavesToViolinPlot
          AdoptFiles Append AppendBoxPlot AppendImage
          AppendLayoutObject AppendMatrixContour AppendText
          AppendToGizmo AppendToGraph AppendToLayout
          AppendToTable AppendViolinPlot AppendXYZContour
          AutoPositionWindow AxonTelegraphFindServers
          BackgroundInfo Beep BoundingBall BoxSmooth BrowseURL
          BuildMenu Button CWT Chart CheckBox CheckDisplayed
          ChooseColor Close CloseHelp CloseMovie CloseProc
          ColorScale ColorTab2Wave Concatenate ControlBar
          ControlInfo ControlUpdate
          ConvertGlobalStringTextEncoding ConvexHull Convolve
          CopyDimLabels CopyFile CopyFolder CopyScales Correlate
          CreateAliasShortcut CreateBrowser Cross CtrlBackground
          CtrlFIFO CtrlNamedBackground Cursor CurveFit
          CustomControl DAQmx_AI_SetupReader DAQmx_AO_SetOutputs
          DAQmx_CTR_CountEdges DAQmx_CTR_OutputPulse
          DAQmx_CTR_Period DAQmx_CTR_PulseWidth DAQmx_DIO_Config
          DAQmx_DIO_WriteNewData DAQmx_Scan DAQmx_WaveformGen
          DPSS DSPDetrend DSPPeriodogram DWT Debugger
          DebuggerOptions DefaultFont DefaultGuiControls
          DefaultGuiFont DefaultTextEncoding DefineGuide
          DelayUpdate DeleteAnnotations DeleteFile DeleteFolder
          DeletePoints Differentiate Display DisplayHelpTopic
          DisplayProcedure DoAlert DoIgorMenu DoUpdate DoWindow
          DoXOPIdle DrawAction DrawArc DrawBezier DrawLine
          DrawOval DrawPICT DrawPoly DrawRRect DrawRect DrawText
          DrawUserShape Duplicate DuplicateDataFolder EdgeStats
          Edit ErrorBars EstimatePeakSizes Execute
          ExecuteScriptText ExperimentInfo ExperimentModified
          ExportGizmo Extract FBinRead FBinWrite FFT FGetPos
          FIFO2Wave FIFOStatus FMaxFlat FPClustering FReadLine
          FSetPos FStatus FTPCreateDirectory FTPDelete
          FTPDownload FTPUpload FastGaussTransform FastOp
          FilterFIR FilterIIR FindAPeak FindContour
          FindDuplicates FindLevel FindLevels FindPeak
          FindPointsInPoly FindRoots FindSequence FindValue
          FuncFit FuncFitMD GBLoadWave GISCreateVectorLayer
          GISGetRasterInfo GISGetRegisteredFileInfo
          GISGetVectorLayerInfo GISLoadRasterData
          GISLoadVectorData GISRasterizeVectorData
          GISRegisterFile GISTransformCoords GISUnRegisterFile
          GISWriteFieldData GISWriteGeometryData GISWriteRaster
          GPIB2 GPIBRead2 GPIBReadBinary2 GPIBReadBinaryWave2
          GPIBReadWave2 GPIBWrite2 GPIBWriteBinary2
          GPIBWriteBinaryWave2 GPIBWriteWave2 GetAxis GetCamera
          GetFileFolderInfo GetGizmo GetLastUserMenuInfo
          GetMarquee GetMouse GetSelection GetWindow GraphNormal
          GraphWaveDraw GraphWaveEdit Grep GroupBox
          HDF5CloseFile HDF5CloseGroup HDF5ConvertColors
          HDF5CreateFile HDF5CreateGroup HDF5CreateLink HDF5Dump
          HDF5DumpErrors HDF5DumpState HDF5FlushFile
          HDF5ListAttributes HDF5ListGroup HDF5LoadData
          HDF5LoadGroup HDF5LoadImage HDF5OpenFile HDF5OpenGroup
          HDF5SaveData HDF5SaveGroup HDF5SaveImage
          HDF5TestOperation HDF5UnlinkObject HDFInfo
          HDFReadImage HDFReadSDS HDFReadVset Hanning
          HideIgorMenus HideInfo HideProcedures HideTools
          HilbertTransform Histogram ICA IFFT ITCCloseAll2
          ITCCloseDevice2 ITCConfigAllChannels2
          ITCConfigChannel2 ITCConfigChannelReset2
          ITCConfigChannelUpload2 ITCFIFOAvailable2
          ITCFIFOAvailableAll2 ITCGetAllChannelsConfig2
          ITCGetChannelConfig2 ITCGetCurrentDevice2
          ITCGetDeviceInfo2 ITCGetDevices2 ITCGetErrorString2
          ITCGetSerialNumber2 ITCGetState2 ITCGetVersions2
          ITCInitialize2 ITCOpenDevice2 ITCReadADC2
          ITCReadDigital2 ITCReadTimer2 ITCSelectDevice2
          ITCSetDAC2 ITCSetGlobals2 ITCSetModes2 ITCSetState2
          ITCStartAcq2 ITCStopAcq2 ITCUpdateFIFOPosition2
          ITCUpdateFIFOPositionAll2 ITCWriteDigital2
          ImageAnalyzeParticles ImageBlend ImageBoundaryToMask
          ImageComposite ImageEdgeDetection ImageFileInfo
          ImageFilter ImageFocus ImageFromXYZ ImageGLCM
          ImageGenerateROIMask ImageHistModification
          ImageHistogram ImageInterpolate ImageLineProfile
          ImageLoad ImageMorphology ImageRegistration
          ImageRemoveBackground ImageRestore ImageRotate
          ImageSave ImageSeedFill ImageSkeleton3d ImageSnake
          ImageStats ImageThreshold ImageTransform
          ImageUnwrapPhase ImageWindow IndexSort InsertPoints
          Integrate Integrate2D IntegrateODE Interp3DPath
          Interpolate2 Interpolate3D JCAMPLoadWave
          JointHistogram KMeans KillBackground KillControl
          KillDataFolder KillFIFO KillFreeAxis KillPICTs
          KillPath KillStrings KillVariables KillWaves
          KillWindow Label Layout LayoutPageAction
          LayoutSlideShow Legend LinearFeedbackShiftRegister
          ListBox LoadData LoadPICT LoadPackagePreferences
          LoadWave Loess LombPeriodogram MCC_FindServers
          MFR_CheckForNewBricklets MFR_CloseResultFile
          MFR_CreateOverviewTable MFR_GetBrickletCount
          MFR_GetBrickletData MFR_GetBrickletDeployData
          MFR_GetBrickletMetaData MFR_GetBrickletRawData
          MFR_GetReportTemplate MFR_GetResultFileMetaData
          MFR_GetResultFileName MFR_GetVernissageVersion
          MFR_GetVersion MFR_GetXOPErrorMessage
          MFR_OpenResultFile
          MLLoadWave Make MakeIndex MarkPerfTestTime
          MatrixConvolve MatrixCorr MatrixEigenV MatrixFilter
          MatrixGLM MatrixGaussJ MatrixInverse MatrixLLS
          MatrixLUBkSub MatrixLUD MatrixLUDTD MatrixLinearSolve
          MatrixLinearSolveTD MatrixMultiply MatrixOP
          MatrixSVBkSub MatrixSVD MatrixSchur MatrixSolve
          MatrixTranspose MeasureStyledText Modify ModifyBoxPlot
          ModifyBrowser ModifyCamera ModifyContour ModifyControl
          ModifyControlList ModifyFreeAxis ModifyGizmo
          ModifyGraph ModifyImage ModifyLayout ModifyPanel
          ModifyTable ModifyViolinPlot ModifyWaterfall
          MoveDataFolder MoveFile MoveFolder MoveString
          MoveSubwindow MoveVariable MoveWave MoveWindow
          MultiTaperPSD MultiThreadingControl NC_CloseFile
          NC_DumpErrors NC_Inquire NC_ListAttributes
          NC_ListObjects NC_LoadData NC_OpenFile NI4882
          NILoadWave NeuralNetworkRun NeuralNetworkTrain
          NewCamera NewDataFolder NewFIFO NewFIFOChan
          NewFreeAxis NewGizmo NewImage NewLayout NewMovie
          NewNotebook NewPanel NewPath NewWaterfall Note
          Notebook NotebookAction Open OpenHelp OpenNotebook
          Optimize PCA ParseOperationTemplate PathInfo
          PauseForUser PauseUpdate PlayMovie PlayMovieAction
          PlaySound PopupContextualMenu PopupMenu Preferences
          PrimeFactors Print PrintGraphs PrintLayout
          PrintNotebook PrintSettings PrintTable Project
          PulseStats PutScrapText Quit RatioFromNumber
          Redimension Remez Remove RemoveContour RemoveFromGizmo
          RemoveFromGraph RemoveFromLayout RemoveFromTable
          RemoveImage RemoveLayoutObjects RemovePath Rename
          RenameDataFolder RenamePICT RenamePath RenameWindow
          ReorderImages ReorderTraces ReplaceText ReplaceWave
          Resample ResumeUpdate Reverse Rotate SQLHighLevelOp
          STFT Save SaveData SaveExperiment SaveGizmoCopy
          SaveGraphCopy SaveNotebook SavePICT
          SavePackagePreferences SaveTableCopy
          SetActiveSubwindow SetAxis SetBackground
          SetDashPattern SetDataFolder SetDimLabel SetDrawEnv
          SetDrawLayer SetFileFolderInfo SetFormula
          SetIdlePeriod SetIgorHook SetIgorMenuMode
          SetIgorOption SetMarquee SetProcessSleep SetRandomSeed
          SetScale SetVariable SetWaveLock SetWaveTextEncoding
          SetWindow ShowIgorMenus ShowInfo ShowTools Silent
          Sleep Slider Smooth SmoothCustom Sort SortColumns
          SoundInRecord SoundInSet SoundInStartChart
          SoundInStatus SoundInStopChart SoundLoadWave
          SoundSaveWave SphericalInterpolate
          SphericalTriangulate SplitString SplitWave Stack
          StackWindows StatsANOVA1Test StatsANOVA2NRTest
          StatsANOVA2RMTest StatsANOVA2Test
          StatsAngularDistanceTest StatsChiTest
          StatsCircularCorrelationTest StatsCircularMeans
          StatsCircularMoments StatsCircularTwoSampleTest
          StatsCochranTest StatsContingencyTable StatsDIPTest
          StatsDunnettTest StatsFTest StatsFriedmanTest
          StatsHodgesAjneTest StatsJBTest StatsKDE StatsKSTest
          StatsKWTest StatsKendallTauTest
          StatsLinearCorrelationTest StatsLinearRegression
          StatsMultiCorrelationTest StatsNPMCTest
          StatsNPNominalSRTest StatsQuantiles
          StatsRankCorrelationTest StatsResample StatsSRTest
          StatsSample StatsScheffeTest StatsShapiroWilkTest
          StatsSignTest StatsTTest StatsTukeyTest
          StatsVariancesTest StatsWRCorrelationTest
          StatsWatsonUSquaredTest StatsWatsonWilliamsTest
          StatsWheelerWatsonTest StatsWilcoxonRankTest String
          StructFill StructGet StructPut SumDimension SumSeries
          TDMLoadData TDMSaveData TabControl Tag TextBox
          ThreadGroupPutDF ThreadStart TickWavesFromAxis Tile
          TileWindows TitleBox ToCommandLine ToolsGrid
          Triangulate3d URLRequest Unwrap VDT2 VDTClosePort2
          VDTGetPortList2 VDTGetStatus2 VDTOpenPort2
          VDTOperationsPort2 VDTRead2 VDTReadBinary2
          VDTReadBinaryWave2 VDTReadHex2 VDTReadHexWave2
          VDTReadWave2 VDTTerminalPort2 VDTWrite2
          VDTWriteBinary2 VDTWriteBinaryWave2 VDTWriteHex2
          VDTWriteHexWave2 VDTWriteWave2 VISAControl VISARead
          VISAReadBinary VISAReadBinaryWave VISAReadWave
          VISAWrite VISAWriteBinary VISAWriteBinaryWave
          VISAWriteWave ValDisplay Variable WaveMeanStdv
          WaveStats WaveTransform WignerTransform WindowFunction
          XLLoadWave cd dir fprintf printf pwd sprintf sscanf
          wfprintf
        )
      end

      def self.object_name
        /\b[a-z][a-z0-9_\.]*?\b/i
      end

      object = self.object_name
      noLineBreak = /(?:[ \t]|(?:\\\s*[\r\n]))+/
      operator = %r([\#$~!%^&*+=\|?:<>/-])
      punctuation = /[{}()\[\],.;]/
      number_float= /0x[a-f0-9]+/i
      number_hex  = /\d+\.\d+(e[\+\-]?\d+)?/
      number_int  = /[\d]+(?:_\d+)*/

      state :root do
        rule %r(//), Comment, :comments

        rule %r/#{object}/ do |m|
          if m[0].downcase =~ /function/
            token Keyword::Declaration
            push :parse_function
          elsif self.class.igorDeclarations.include? m[0].downcase
            token Keyword::Declaration
            push :parse_variables
          elsif self.class.keywords.include? m[0].downcase
            token Keyword
          elsif self.class.igorConstants.include? m[0].downcase
            token Keyword::Constant
          elsif self.class.igorFunction.include? m[0].downcase
            token Name::Builtin
          elsif self.class.igorOperation.include? m[0].downcase
            token Keyword::Reserved
            push :operationFlags
          elsif m[0].downcase =~ /\b(v|s|w)_[a-z]+[a-z0-9]*/
            token Name::Constant
          else
            token Name
          end
        end

        mixin :preprocessor
        mixin :waveFlag

        mixin :characters
        mixin :numbers
        mixin :whitespace
      end

      state :preprocessor do
        rule %r((\#)(#{object})) do |m|
          if self.class.preprocessor.include? m[2].downcase
            token Comment::Preproc
          else
            token Punctuation, m[1] #i.e. ModuleFunctions
            token Name, m[2]
          end


        end
      end

      state :assignment do
        mixin :whitespace
        rule %r/\"/, Literal::String::Double, :string1 #punctuation for string
        mixin :string2
        rule %r/#{number_float}/, Literal::Number::Float, :pop!
        rule %r/#{number_int}/, Literal::Number::Integer, :pop!
        rule %r/[\(\[\{][^\)\]\}]+[\)\]\}]/, Generic, :pop!
        rule %r/[^\s\/\(]+/, Generic, :pop!
        rule(//) { pop! }
      end

      state :parse_variables do
        mixin :whitespace
        rule %r/[=]/, Punctuation, :assignment
        rule object, Name::Variable
        rule %r/[\[\]]/, Punctuation # optional variables in functions
        rule %r/[,]/, Punctuation, :parse_variables
        rule %r/\)/, Punctuation, :pop! # end of function
        rule %r([/][a-z]+)i, Keyword::Pseudo, :parse_variables
        rule(//) { pop! }
      end

      state :parse_function do
        rule %r([/][a-z]+)i, Keyword::Pseudo # only one flag
        mixin :whitespace
        rule object, Name::Function
        rule %r/[\(]/, Punctuation, :parse_variables
        rule(//) { pop! }
      end

      state :operationFlags do
        rule %r/#{noLineBreak}/, Text
        rule %r/[=]/, Punctuation, :assignment
        rule %r([/][a-z]+)i, Keyword::Pseudo, :operationFlags
        rule %r/(as)(\s*)(#{object})/i do
          groups Keyword::Type, Text, Name::Label
        end
        rule(//) { pop! }
      end

      # inline variable assignments (i.e. for Make) with strict syntax
      state :waveFlag do
        rule %r(
          (/(?:wave|X|Y))
          (\s*)(=)(\s*)
          (#{object})
          )ix do |m|
          token Keyword::Pseudo, m[1]
          token Text, m[2]
          token Punctuation, m[3]
          token Text, m[4]
          token Name::Variable, m[5]
        end
      end

      state :characters do
        rule %r/\s/, Text
        rule %r/#{operator}/, Operator
        rule %r/#{punctuation}/, Punctuation
        rule %r/\"/, Literal::String::Double, :string1 #punctuation for string
        mixin :string2
      end

      state :numbers do
        rule %r/#{number_float}/, Literal::Number::Float
        rule %r/#{number_hex}/, Literal::Number::Hex
        rule %r/#{number_int}/, Literal::Number::Integer
      end

      state :whitespace do
        rule %r/#{noLineBreak}/, Text
      end

      state :string1 do
        rule %r/%\w\b/, Literal::String::Other
        rule %r/\\\\/, Literal::String::Escape
        rule %r/\\\"/, Literal::String::Escape
        rule %r/\\/, Literal::String::Escape
        rule %r/[^"]/, Literal::String
        rule %r/\"/, Literal::String::Double, :pop! #punctuation for string
      end

      state :string2 do
        rule %r/\'[^']*\'/, Literal::String::Single
      end

      state :comments do
        rule %r{([/]\s*)([@]\w+\b)}i do
          # doxygen comments
          groups Comment, Comment::Special
        end
        rule %r/[^\r\n]/, Comment
        rule(//) { pop! }
      end
    end
  end
end
