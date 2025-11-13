* Encoding: UTF-8.

DATASET ACTIVATE DataSet1.
COMPUTE DASS_DEP=DASS21_3 + DASS21_5 + DASS21_10 + DASS21_13 + DASS21_16 + DASS21_17 + DASS21_21.
EXECUTE.

COMPUTE DASS_ANX=DASS21_2 + DASS21_4 + DASS21_7 + DASS21_9 + DASS21_15 + DASS21_19 + DASS21_20.
EXECUTE.

COMPUTE DASS_STR=DASS21_1 + DASS21_6 + DASS21_8 + DASS21_11 + DASS21_12 + DASS21_14 + DASS21_18.
EXECUTE.

COMPUTE Hogg_total=HoggScale_1 + HoggScale_2 + HoggScale_3 + HoggScale_4 + HoggScale_5 + 
    HoggScale_6 + HoggScale_7 + HoggScale_8 + HoggScale_9 + HoggScale_10 + HoggScale_11 + HoggScale_12 
    + HoggScale_13.
EXECUTE.

COMPUTE Hogg_affective=(HoggScale_1 + HoggScale_2 + HoggScale_3 + HoggScale_4) / 4 .
EXECUTE.

COMPUTE Hogg_rumination=(HoggScale_5 + HoggScale_6 + HoggScale_7) / 3 .
EXECUTE.

COMPUTE Hogg_behavioural=(HoggScale_8 + HoggScale_9 + HoggScale_10) / 3 .
EXECUTE.

COMPUTE Hogg_PI=(HoggScale_11 + HoggScale_12 + HoggScale_13) / 3 .
EXECUTE.

COMPUTE Coping_PF=(Coping_1 + Coping_2 + Coping_3) / 3.
EXECUTE.

COMPUTE Coping_EF=(Coping_4 + Coping_5 + Coping_6 + Coping_7) / 4.
EXECUTE.

COMPUTE Coping_avoidance=(Coping_8 + Coping_9 + Coping_10 + Coping_11) / 4.
EXECUTE.

RECODE SPOS_1 SPOS_2 SPOS_3 SPOS_4 SPOS_5 SPOS_6 SPOS_7 SPOS_8 (1=0) (2=1) (3=2) (4=3) (5=4) (6=5) 
    (7=6) INTO SPOS_1R SPOS_2R SPOS_3R SPOS_4R SPOS_5R SPOS_6R SPOS_7R SPOS_8R.
VARIABLE LABELS  SPOS_1R 'SPOS_1R' /SPOS_2R 'SPOS_2R' /SPOS_3R 'SPOS_3R' /SPOS_4R 'SPOS_4R' 
    /SPOS_5R 'SPOS_5R' /SPOS_6R 'SPOS_6R' /SPOS_7R 'SPOS_7R' /SPOS_8R 'SPOS_8R'.
EXECUTE.

RECODE SPOS_2R SPOS_3R SPOS_5R SPOS_7R (0=6) (1=5) (2=4) (3=3) (4=2) (5=1) (6=0) INTO SPOS_2RRev 
    SPOS_3RRev SPOS_5RRev SPOS_7RRev.
VARIABLE LABELS  SPOS_2RRev 'SPOS_2RRev' /SPOS_3RRev 'SPOS_3RRev' /SPOS_5RRev 'SPOS_5RRev' 
    /SPOS_7RRev 'SPOS_7RRev'.
EXECUTE.

COMPUTE SPOS_Total=SPOS_1R + SPOS_2RRev + SPOS_3RRev + SPOS_4R + SPOS_5RRev + SPOS_6R + SPOS_7RRev 
    + SPOS_8R.
EXECUTE.

COMPUTE SWEMWBS_Total=SWEMWBS_1 + SWEMWBS_2 + SWEMWBS_3 + SWEMWBS_4 + SWEMWBS_5 + SWEMWBS_6 + 
    SWEMWBS_7.
EXECUTE.

RECODE CBIPersonal_1 CBIPersonal_2 CBIPersonal_3 CBIPersonal_4 CBIPersonal_5 CBIPersonal_6 (1=0) 
    (2=25) (3=50) (4=75) (5=100) INTO CBIPersonal_1R CBIPersonal_2R CBIPersonal_3R CBIPersonal_4R 
    CBIPersonal_5R CBIPersonal_6R.
VARIABLE LABELS  CBIPersonal_1R 'CBIPersonal_1R' /CBIPersonal_2R 'CBIPersonal_2R' 
    /CBIPersonal_3R 'CBIPersonal_3R' /CBIPersonal_4R 'CBIPersonal_4R' /CBIPersonal_5R 'CBIPersonal_5R' 
    /CBIPersonal_6R 'CBIPersonal_6R'.
EXECUTE.


COMPUTE CBIPersonal_TotalMean=(CBIPersonal_1R + CBIPersonal_2R + CBIPersonal_3R + CBIPersonal_4R + 
    CBIPersonal_5R + CBIPersonal_6R) / 6.
EXECUTE.

RECODE CBIWork1_1 CBIWork1_2 CBIWork1_3 CBIWork2_1 CBIWork2_2 CBIWork2_3 CBIWork2_4 (1=0) (2=25) 
    (3=50) (4=75) (5=100) INTO CBIWork_1R CBIWork_2R CBIWork_3R CBIWork_4R CBIWork_5R CBIWork_6R 
    CBIWork_7R.
VARIABLE LABELS  CBIWork_1R 'CBIWork_1R' /CBIWork_2R 'CBIWork_2R' /CBIWork_3R 'CBIWork_3R' 
    /CBIWork_4R 'CBIWork_4R' /CBIWork_5R 'CBIWork_5R' /CBIWork_6R 'CBIWork_6R' /CBIWork_7R 'CBIWork_7R'.    
EXECUTE.

RECODE CBIWork_7R (0=100) (25=75) (50=50) (75=25) (100=0) INTO CBIWork_7RRev.
VARIABLE LABELS  CBIWork_7RRev 'CBIWork_7RRev'.
EXECUTE.

COMPUTE CBIWork_TotalMean=(CBIWork_1R + CBIWork_2R + CBIWork_3R + CBIWork_4R + CBIWork_5R + 
    CBIWork_6R + CBIWork_7RRev) / 7.
EXECUTE.

COMPUTE WAMI_Total=WAMI_1 + WAMI_2 + WAMI_3 + WAMI_4 + WAMI_5 + WAMI_6 + WAMI_7 + WAMI_8 + WAMI_9 + 
    WAMI_10.
EXECUTE.

COMPUTE WAMI_PM=WAMI_1 + WAMI_4 + WAMI_5 + WAMI_8 .
EXECUTE.

COMPUTE WAMI_MM=WAMI_2 + WAMI_7 + WAMI_9 .
EXECUTE.

COMPUTE WAMI_GG=WAMI_3 + WAMI_6 + WAMI_10 .
EXECUTE.
