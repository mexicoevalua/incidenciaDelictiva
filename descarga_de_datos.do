/*******************************************************************************
AUTHOR: Leonel Fernandez 
ORGANIZATION: Mexico Evalua
URL: github.com/mexicoevalua/incidenciaDelictiva/blob/master/descarga_de_datos.do
DATE:January, 2015
PURPOSE: Create clean database and indicators of official crime data in Mexico
DATA IN: 
			-IncidenciaDelictiva_FueroComun_Estatal_1997-{MONTH_YEAR}.xls 
			(Raw monthly data of 66 crime types in the 32 federative entities 
			of MŽxico, 1997-actual [Updates in the 20th of each month])
			
			-Incidencia Delictiva FC Municipal 2011 -{YEAR}.xlsx"(Raw monthly 
			data of 66 crime types in all the municipalities 
			of MŽxico, 1997-actual [Updates in the 20th of each month])
			
			-state-population.csv (Cleaned estimated mid-year population data at 
			the state level from the CONAPO (2010) by Diego Valle
			https://github.com/diegovalle/conapo-2010
			
			-municipio-population2010-2030.csv (Cleaned estimated mid-year 
			population data at the municipal level from the CONAPO (2010)
			by Diego Valle.  https://github.com/diegovalle/conapo-2010

DATA OUT: 
			fuero-comun-estados.csv
			fuero-comun-municipios.csv
*******************************************************************************/
version 13.1
clear all
set more off


* Defining globals. Change working directory HERE*
global micrositio "~/Desktop" /*Change the '~' simbol with the directory where the
						Micrositio is stored */
global files "$micrositio/Micrositio/incidenciaDelictiva/data"


*Downloading datasets. The program needs at least 2.5 GB of free Hard Disk space*
cd "$files"
/*IMPORTANT:After the 20th of each month check the new URL in SESNSP site and  
			1)Change updated URLs in /*1*/ & /*3*/ (lines 44 & 48)
			2)Chamge updated files names in /*2*/ & /*4*/(line 46 & 50)		*/
/*1*/ copy "http://www.secretariadoejecutivo.gob.mx/docs/pdfs/incidencia%20delictiva%20del%20fuero%20comun/IncidenciaDelictiva_FueroComun_Estatal_1997-Diciembre2014.zip" incidencia_e.zip, replace
		unzipfile "incidencia_e.zip", replace
/*2*/ global state "$files/IncidenciaDelictiva_FueroComun_Estatal_1997-Diciembre2014.xlsx"
		copy "$state" IncidenciaDelictivaEstatal.xlsx, replace
/*3*/ copy "http://secretariadoejecutivo.gob.mx/Incidencia%20Municipal%20Diciembre/IncidenciaDelictiva-Municipal2011-2014.zip" incidencia_m.zip, replace
		unzipfile "incidencia_m.zip", replace
/*4*/ global municip "$files/Incidencia Delictiva FC Municipal 2011 - 2014.xlsx"
		copy "$municip" IncidenciaDelictivaMunicipal.xlsx, replace
copy "https://raw.githubusercontent.com/diegovalle/conapo-2010/master/clean-data/state-population.csv" statepop.csv
copy "https://raw.githubusercontent.com/diegovalle/conapo-2010/master/clean-data/municipio-population2010-2030.csv" munpop.csv, replace

*STATES***********************************************************************
*Cleaning population data set*
clear
import delimited "$files/statepop.csv"
drop if year > 2014 | year <1997
rename statecode state_code
save statepop.dta, replace

*Cleaning SESNSP's crime data set*

clear
import excel using "IncidenciaDelictivaEstatal.xlsx", firstrow
drop if AO == .

*Erase leading, trailing and intermediate blank spaces in all string variables
replace  ENTIDAD = trim(itrim(ENTIDAD))
replace  MODALIDAD = trim(itrim(MODALIDAD))
replace  TIPO = trim(itrim(TIPO))
replace  SUBTIPO = trim(itrim(SUBTIPO))

*Encoding state codes*
encode ENTIDAD, gen(state_code) 
drop ENTIDAD TOTALAO

recode state_code (5=45) (6=46)
recode state_code (7=5) (8=6)
recode state_code (45=7) (46=8)

label define state_code 5 "COAHUILA", modify
label define state_code 6 "COLIMA", modify
label define state_code 7 "CHIAPAS", modify
label define state_code 8 "CHIHUAHUA", modify

*Renaming variables*
rename (AO MODALIDAD TIPO SUBTIPO ENERO FEBRERO MARZO ABRIL MAYO JUNIO JULIO /// 
		AGOSTO SEPTIEMBRE OCTUBRE NOVIEMBRE DICIEMBRE) 						 ///
       (year category type subtype count1 count2 count3 count4 count5 count6 ///
		count7 count8 count9 count10 count11 count12)
		
*Reshaping to long format*		
reshape long count, i(year category type subtype state_code) j(month)
destring count, replace

*Creating crime variable wich groups all categories of "ROBO" in just one*
gen crime = category
replace crime = "ROBO" if word(category,1) == "ROBO"

*Merging with population data base*
merge m:1 year state_code using "$files/statepop.dta", keepusing(total) ///
			nogenerate
rename total population

*Ordering variables and sorting cases*
order state_code year month crime category type subtype count population
sort state_code year crime category type subtype month

*Exporting to .cvs and saveing in .dta*
export delimited using "$files/fuero-comun-estados.csv", nolabel replace
save fuero-comun-estados.dta, replace


*Stop here if you want to keep all files 
*deleting files*
rm incidencia_e.zip
rm "$state"
rm statepop.dta
rm fuero-comun-estados.dta
rm IncidenciaDelictivaEstatal.xlsx

*MUNICIPALITIES****************************************************************
*Cleaning population data set*
clear
import delimited "$files/munpop.csv"
drop if sex == "Males" | sex == "Females" 
drop sex
drop if year == 2010 | year >2014
nsplit code, d(2 3) gen(state_code mun_code)
format code %05.0f
rename code id

save munpop.dta, replace

*Cleaning SESNSP's crime data set*

clear
set excelxlsxlargefile on
import excel using "IncidenciaDelictivaMunicipal.xlsx", firstrow
drop if AO == .
save fuero-comun-municipios.dta, replace

**Erase leading, trailing and intermediate blank spaces in all string variables
replace  ENTIDAD = trim(itrim(ENTIDAD))
replace  MUNICIPIO = trim(itrim(MUNICIPIO))
replace  MODALIDAD = trim(itrim(MODALIDAD))
replace  TIPO = trim(itrim(TIPO))
replace  SUBTIPO = trim(itrim(SUBTIPO))

replace SUBTIPO ="CON ARMA DE FUEGO" if SUBTIPO == "POR ARMA DE FUEGO"
replace SUBTIPO ="CON ARMA BLANCA" if SUBTIPO == "POR ARMA BLANCA"


*Encoding state codes*

drop ENTIDAD MUNICIPIO


*renaming variables*
rename (AO INEGI MODALIDAD TIPO SUBTIPO ENERO FEBRERO MARZO ABRIL MAYO JUNIO JULIO /// 
		AGOSTO SEPTIEMBRE OCTUBRE NOVIEMBRE DICIEMBRE) 						 ///
       (year id category type subtype count1 count2 count3 count4 count5 count6 ///
		count7 count8 count9 count10 count11 count12)
		
nsplit id, d(2 3) gen(state_code mun_code)
		
*Reshaping to long format*		
reshape long count, i(year id category type subtype state_code mun_code) j(month)
destring count, replace

*Creating crime variable wich groups all categories of "ROBO" in just one*
gen crime = category
replace crime = "ROBOS" if word(category,1) == "ROBO"

*Merging with population data base*
merge m:1 year state_code mun_code id using "$files/munpop.dta", keepusing(population) ///
			nogenerate


*Ordering variables and sorting cases*
order state_code mun_code year month crime category type subtype count population id
sort state_code mun_code year crime category type subtype month

*Exporting to .cvs and saveing in .dta*
export delimited using "$files/fuero-comun-municipios.csv", nolabel replace
save fuero-comun-municipios.dta, replace


*Stop here if you want to keep all files 
*deleting files*
rm incidencia_m.zip
rm "$municip"
rm munpop.dta
rm fuero-comun-municipios.dta
rm IncidenciaDelictivaMunicipal.xlsx

************************End of do-file*****************************************

