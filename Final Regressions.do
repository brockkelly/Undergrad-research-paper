**** Final Regression Analysis ***

* Here we will examine how each of our measures of monetary policy shock effect industry revenue and equity price

* collects data on aggregate revenue, price, net income from WRDS (net income has been excluded from our analysis)

use "AGG REV, PRICE, NETINC.dta", clear
capture graph drop _all

* creating a time variable and dropping data before 2005
tsset dq
drop if dq < tq(2005q1)

* this is our dataset for key macro variables as well as our monetary shocks
merge 1:1 dq using "FRED Data.dta"
drop _merge

* dropping 2020q4
drop in 64

* generating aggregates

egen totalnetinc = rowtotal(netinc*)
egen totalrev = rowtotal(rev*)
egen totalprice = rowtotal(price*)
sort dq

* these two loops give us some info on the relative share of revenue and price that each industry has in the S&P 500

foreach var of varlist rev*{
gen share`var' = `var'/totalrev
summarize share`var', detail
}

foreach var of varlist price*{
gen share`var' = `var'/totalrev
summarize share`var', detail
}

* generating change variables and creating ma of our industry fundmanentals

foreach var of varlist totalrev totalprice totalnetinc rev* price* netinc* DFF INDPRO CPIAUCSL M1{
tssmooth ma ma`var' = `var', window(1 1 1)
generate ch`var' = log(ma`var'/l.ma`var')*100

}


* this is a function to create quarterly dummy variables that will be used in our regressions

gen td = dofq(dq)
gen q = quarter(td)

local i=1
foreach a of numlist 1/4 {
gen q`i'=(q==1)
local i = `i'+1
di `i'
}


* Dedola and Lippi Method
foreach var of varlist totalrev totalprice rev* price* {
quietly var q CPIAUCSL M1 INDPRO DFF ch`var', lags(1/4) small
irf create irf, set(irfs, replace) step(12)
irf table cirf, impulse(DFF) response(ch`var')
irf graph cirf, yline(0) impulse(DFF) response(ch`var') title("Cumulative IRF Shock = Federal Funds Rate", size(small))
graph rename `var'irf

}


* Javier Nieto (2016)
foreach var of varlist totalrev totalprice rev* price* {

quietly var q ms ch`var', lags(1/12) small
irf create irf, set(irfs, replace) step(12)
irf table cirf, impulse(ms) response(ch`var')
irf graph cirf, yline(0) impulse(ms) response(ch`var') title("Cumulative IRF Shock = Romer Shock", size(small))
graph rename `var'irfnieto

}


* Unconventional Policy

*LSAP

foreach var of varlist totalrev totalprice rev* price* {

varsoc qe ch`var', maxlag(12)
quietly var q qe ch`var', lags(1/12) small
irf create irf, set(irfs, replace) step(12)
irf table cirf, impulse(qe) response(ch`var')
irf graph cirf, yline(0) impulse(qe) response(ch`var') title("Cumulative IRF Shock = Large-Scale Asset Purchases", size(small))
graph rename `var'irflsap

}


*Forward Guidance

foreach var of varlist totalrev totalprice rev* price* {

varsoc fg ch`var', maxlag(12)
quietly var q fg ch`var', lags(1/12) small
irf create irf, set(irfs, replace) step(12)
irf table cirf, impulse(fg) response(ch`var')
irf graph cirf, yline(0) impulse(fg) response(ch`var') title("Cumulative IRF Shock = Forward Guidance ", size(small))
graph rename `var'irffg

}



*Shadow Rate

foreach var of varlist totalrev totalprice rev* price* {

varsoc sh ch`var', maxlag(12)
quietly var q sh ch`var', lags(1/12) small
irf create irf, set(irfs, replace) step(12)
irf table cirf, impulse(sh) response(ch`var')
irf graph cirf, yline(0) impulse(sh) response(ch`var') title("Cumulative IRF Shock = Shadow Rate ", size(small))
graph rename `var'irfsh

}


* visualizing the effect of of each measure on total revenue
graph combine totalrevirf totalrevirfnieto totalrevirflsap totalrevirffg totalrevirfsh, title("Effect of Each Measure on Revenue", size(small))
graph rename rev

* visualizing the effect of each measure on total price
graph combine totalpriceirf totalpriceirfnieto totalpriceirflsap totalpriceirffg totalpriceirfsh, title("Effect of Each Measure on Price", size(small))
graph rename price

