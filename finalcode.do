* Step1: Data Cleaning *
cd "/Users/alissa/Dropbox/Student material/Empirical project/Data/"
* EmployeeStatus *
use "EmployeeStatus.dta", clear

describe

codebook
*** no missing variables!

summarize personid, detail
summarize treatment,detail
*** no repeating personid, treatment is  about 50%

tabulate personid
tabulate treatment

histogram treatment

scatter treatment personid
*** no obvious relationship between personid and treatment

browse
save "EmployeeStatus.dta",replace

* EmployeeCharacteristics *
use "EmployeeCharacteristics.dta", clear

describe

codebook
*** Something wrong with range of prior_experience,age and tenure! 

summarize personid, detail
summarize prior_experience,detail
* -99 is unreasonable, 24.888889 ???
summarize age,detail
* -99 is unreasonable
summarize tenure,detail
* -99 is unreasonable
summarize basewage,detail
summarize bonus,detail
summarize grosswage, detail
summarize costofcommute,detail
summarize rental,detail
summarize male,detail
summarize married,detail
summarize high_school,detail

tabulate personid
tabulate prior_experience
* -99 is unreasonable
tabulate age
* -99 is unreasonable
tabulate tenure
* -99 is unreasonable
tabulate basewage
tabulate bonus
tabulate grosswage
tabulate costofcommute
tabulate rental
tabulate male
tabulate married
tabulate high_school

histogram personid
histogram prior_experience
* -99 is unreasonable
histogram age
* -99 is unreasonable
histogram tenure
* -99 is unreasonable
histogram basewage
histogram bonus
histogram grosswage
histogram costofcommute
histogram rental
histogram male
histogram married
histogram high_school

foreach v of varlist _all{ 				
		replace `v' = . if `v' == -99 		
}
*** replace -99 with na

foreach v of varlist _all{ 				
		replace `v' = 25 if `v' > 24 & `v' < 25
}
*** replace 24.888889 with 25

browse
save "EmployeeCharacteristics.dta",replace

* Performance_Panel.dta *
use "Performance_Panel.dta", clear

describe

codebook

summarize personid, detail
summarize year,detail
summarize month,detail
summarize post,detail
summarize performance_score,detail
*** 1000 is out of range!
summarize total_monthly_calls,detail
*** -999999 is unreasonalble!
summarize calls_per_hour,detail

tabulate personid
tabulate year
tabulate post
tabulate month
tabulate performance_score
*** three 1000!
tabulate total_monthly_calls
***  -999999!
tabulate calls_per_hour
*** 200 is to many!

histogram performance_score
*** three 1000!
histogram total_monthly_calls
***  -999999!
histogram calls_per_hour
*** 200 is to many!

foreach v of var performance_score*{ 				
		replace `v' = . if `v' == 1000		
}
*** change 1000 to na

foreach v of var total_monthly_calls*{ 				
		replace `v' = . if `v' == -999999		
}
*** change -999999 to na

foreach v of var calls_per_hour*{ 				
		replace `v' = . if `v' == 200		
}
*** change 200 to na

browse
save "Performance_Panel.dta",replace

* Performance.dta *
use "Performance.dta", clear

describe

codebook

summarize personid, detail
summarize post,detail
summarize performance_score,detail
*** 176.3382 and 278.1695
summarize total_monthly_calls,detail
*** -108951.9 and 0
summarize calls_per_hour,detail
*** 42.67397 is too much!

tabulate personid
tabulate post
tabulate performance_score
tabulate total_monthly_calls
tabulate calls_per_hour

histogram performance_score
histogram total_monthly_calls
histogram calls_per_hour

foreach v of var performance_score*{ 				
		replace `v' = . if `v' > 100		
}
*** change 176.3382 and 278.1695 to na

foreach v of var total_monthly_calls*{ 				
		replace `v' = . if `v' <= 0	
}
*** change -108951.9 and 0 to na

foreach v of var calls_per_hour*{ 				
		replace `v' = . if `v' > 42
}
*** change 42.67397 to na

browse
save "Performance.dta",replace

* merge *
merge m:1 personid using "EmployeeStatus.dta"
drop if _merge == 2
drop _merge
save "Performance.dta",replace

* Balance table: test whether the groups are actually similar at baseline *
use "EmployeeCharacteristics.dta", clear
merge m:1 personid using "EmployeeStatus.dta"
drop if _merge == 2
drop _merge

* ssc install balancetable
eststo clear
eststo:balancetable treatment prior_experience age tenure basewage bonus grosswage costofcommute rental male married high_school using "/Users/alissa/Dropbox/Student material/Empirical project/Data/balance_table.xls",replace

* draw picture to show whether the assumption of differences in differences is true
use "Performance_Panel.dta",clear
merge m:1 personid using "EmployeeStatus.dta"
drop if _merge == 2
drop _merge
save "Performance_Panel.dta",replace

g time=monthly(string(year)+"-"+string(month),"YM")
format time %tm
bys treatment time: egen m = mean(performance_score)

gen performance_treatment = m if treatment == 1
gen performance_control = m if treatment == 0

twoway connected performance_treatment performance_control time,title("Performance Changes by Time in Both Groups") xtitle("Month") ytitle("Performance Score") xline(611)
graph export "Fig1.png", replace

* regression *
use "Performance.dta", clear
gen treatmentXpost = treatment * post
gen lperformance = log(performance_score)

eststo clear
eststo: reg lperformance post treatment treatmentXpost,cluster(personid) 
esttab using "/Users/alissa/Dropbox/Student material/Empirical project/Data/regression_results_con.rtf",replace

