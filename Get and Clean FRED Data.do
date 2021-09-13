clear
* collecting data from FRED

freduse WALCL DFEDTARU DFEDTAR EFFR A191RL1Q225SBEA GDPC1CTMLR UNRATE UNRATECTMLR T10YIE T10YFF TREASURY TREAS1T5 TREAS10Y TREAS5T10 USD3MTD156N TEDRATE CPIAUCSL INDPRO M1 DFF TREAS911Y TREAS15 TREAS1590

* rename 
tsset daten
keep if daten > td(01jan2005)
rename A191RL1Q225SBEA GDP
rename T10YIE inflation
rename WALCL fedbalance

* here we are creating the measure of the size and ratio of long-term debt of the fed's balance sheet 'fed'

* these are the size of the holdings of assets of varying maturities

label variable TREAS15 "<15 days"
label variable TREAS1590 "15 to 90 days"
label variable TREAS911Y "90 days to a year"
label variable TREAS1T5 "1-5 years"
label variable TREAS5T10 "5-10 Years"
label variable TREAS10Y "> 10 years"

* a visualization of these holdings

tsline(TREAS15 TREAS1590 TREAS911Y TREAS1T5 TREAS5T10 TREAS10Y)
graph rename fedholdings

* here we will develop measures of the size of short and long term debt assets

egen shortterm = rowtotal(TREAS15 TREAS1590 TREAS911Y)
egen longterm = rowtotal(TREAS1T5 TREAS5T10 TREAS10Y)

* this is the proportion of long-term debt of total debt securities (treasury securities)
gen debtratio = longterm/(shortterm + longterm)
tsline(debtratio)

* we multiply this by the total balance of the fed to incorporate the size of the total balance sheet

gen fed = debtratio*fedbalance

* Here I am creating new variables for the intended federal funds rate, unemployment forecasts, and forecasts  which combine the datasets on before and after ~ 2008 when the fed began collecting data on forecasts.
* The data set from pre 2008/2009 is actual data, not forecasts.

generate intff = DFEDTAR if daten < td(16dec2008) 
replace intff = DFEDTARU if daten > td(15dec2008)

drop DFEDTAR DFEDTARU

generate unemp = UNRATE if daten < td(18feb2009)
replace unemp = UNRATECTMLR if daten > td(17feb2009)

drop UNRATE UNRATECTMLR

* we are forced to just use the actual values of gdp

generate gdp = GDP /*if daten < td(18feb2009)
replace gdp = GDPC1CTMLR if daten > td(17feb2009) */

drop GDP GDPC1CTMLR

* generating quarter variable

gen dq = qofd(daten)
format dq %tq

* collapsing all variable by the mean observations

collapse unemp gdp intff EFFR inflation fedbalance er spread TREASURY TREAS1T5 TREAS10Y TREAS5T10 CPIAUCSL INDPRO M1 DFF TEDRATE fed, by(dq)

tsset dq

* appending the file which contains the wu-xia shadow rate

merge 1:1 dq using "shadow.dta"
drop _merge


* filling down missing variables

foreach var of varlist unemp gdp intff EFFR inflation fedbalance shadow{

replace `var' = `var'[_n-1] if missing(`var')

}


* generating change variables for each variable, javier nieto uses absolute changes in his analysis so we will do this as well (all variables are already percentage changes)

foreach var of varlist gdp inflation intff shadow {
generate ch`var' = (`var'-l.`var')
}

* generating change variables for our measures of unconventional policy

foreach var of varlist fedbalance TEDRATE fed{
gen ch`var' = log(`var'/l.`var')
}

* generating previous variables for monetary series error term regression

foreach var of varlist intff fedbalance spread shadow TEDRATE fed{
gen pre`var' = l.`var'
}

* These are our regressions which we will collect the error terms from, which will be our measure of monetary policy shocks, all of them control for forecasts of gdp growth, inflation, and unemployment.

regress chintff preintff L(-1/2).gdp  L(-1/2).chgdp L(-1/2).inflation L(-1/2).chinflation unemp
	predict ms, residuals
	label variable ms "Stength of Interest Rate Shock"
	replace ms = ms

regress chfed prefed L(1/4).gdp  L(1/4).chgdp L(1/4).inflation L(1/4).chinflation L(1/4).spread L(1/4).intff unemp
	predict qe, residuals
	label variable qe "Strength of QE Shock"
	replace qe = qe
	
regress chTEDRATE preTEDRATE L(1/4).gdp  L(1/4).chgdp L(1/4).inflation L(1/4).chinflation
	predict fg, residuals
	label variable fg "Forward Guidance"

regress chshadow preshadow L(1/4).gdp  L(1/4).chgdp L(1/4).inflation L(1/4).chinflation unemp
	predict sh, residuals
	label variable sh "Shadow Rate Shock"
	replace sh = sh

* Here is a visualization of all of shocks: Romer shock, LSAP/QE shock, forward guidance shock, and shadow rate shock.

tsline(ms qe fg sh), title("Visualization of the Relative Size of Shocks")

* do these measures satisfy the requirements for stationarity?

foreach var of varlist ms qe fg sh {
ac `var'
graph rename ac`var'
}

save "FRED Data.dta", replace













