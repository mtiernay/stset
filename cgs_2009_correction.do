*********************************************************************
* Filename: cgs_2009_correction.do
* Data: cgs_jcrcox.dta
* Author: Michael Tiernay
* Purpose: Replicate CGS 2009 after changing how the data is stset
*********************************************************************


clear
set more off


* Load in the replication data from:
/* Cunningham, Gleditsch, Salehyan. 2009.
"It Takes Two: A Dyadic Analysis of Civil War Duration and Outcome."
Journal of Conflict Resolution

This file replicates the regessions reported in the paper 

dacunnin@iastate.edu
ksg@essex.ac.uk
idean@unt.edu
*/

use "/Volumes/mrt265/backup/rebel_leaders/DS_10.1177_0022002709336458/cgs_jcrcox.dta", clear


* Replicate Table 3: Disaggregated strength variables
stcox tc scc mcap arcp fcap lpw terr coups ef ethnic lngdppc demdum act2 lnpop, nohr cluster(confid)


* Display the hazard rate, if desired
*stcurve, hazard


*Observe how the data is currently stset in stata
stset

*The output wil display the following:
/*
-> stset useend, id(dyadid) failure(term==1) time0(usestart) origin(time
                 d(01jan1944))

                id:  dyadid
     failure event:  term == 1
obs. time interval:  (usestart, useend]
 exit on or before:  failure
    t for analysis:  (time-origin)
            origin:  time d(01jan1944)

------------------------------------------------------------------------------
     2426  total obs.
        0  exclusions
------------------------------------------------------------------------------
     2426  obs. remaining, representing
      404  subjects
      356  failures in single failure-per-subject data
   782842  total analysis time at risk, at risk from t =         0
                             earliest observed entry t =       651
                                  last observed exit t =     21914
*/


*******************************************************************************


/*

Note that the data are in the form of 'multiple-record data' that allow for 
time-varying covariates.  In the above code, the following terms are used:

useend - the date this particular observation ends (the 31st of december for
the given year if the conflict did not terminate)

dyadid - the id for this conflict dyad

failure - whether the conflict ended during the observed year 

usestart - the date the particular observation begins (the same date as
useend for the previous year if the conflict did not initiate in this
particular year)

origin(time d(01jan1944)) - this is telling stata that each observation 
becomes at risk on the first of january, 1944


*/



*******************************************************************************

/*
The confusion seems to be stemming from the use of the usestart, useend, and 
origin commands.  What (I think) this is telling stata is that each conflcict
becomes at risk for failure on january 1st, 1944.  This, of course, is not 
possible because none of the conflicts have yet to start, and are therefore
not at risk for failure.  

Stata thinks that all conflicts are at risk, but we simply do not observe them 
at this point in their lifespan.  When a conflict does begin, stata thinks that
we finally are observing them.  The first day of conflict should be t = 0. 
However, using this coding scheme, this is not the case.  Assume a conflict
began on january 1st, 1945.  Stata would code this as t = 366, and not as
t = 0.  

Below I correct for this by allowing the start date for the first year of
a conflict to be t = 0. 

*/



*******************************************************************************
* Generating a variable, t, that is the enddate of a particular observation
* (december 31st if the conflict did not end) minus the start date of the 
* conflict.  This coding scheme follows the suggestions in Example 3 of the
* Stata 11 reference manual entry for stset titled 'Multiple-record data'.

* This set of lines generates a variable, counter_start, which identifies the 
* start date for the first year a particular conflict enters the dataset
sort dyadid year
by dyadid: gen counter = _n
gen counter_start = usestart if counter == 1

* This line generates a variable, conflict_start_date, which applies
* the counter_start variable to all observations of a particular conflict
by dyadid: gen conflict_start_date = sum(counter_start)

* This line generates a variable, t, that is the amount of time that has 
* progressed from the beginning of the conflict to the end of a particular
* observation.  For example, if a conflict began on january 1st, 1990, and
* this particular observation was for 1991, then useend would be december 31st,
* 1991, and t would be (11/31/1991-01/01/1990) = 730
gen t = useend - conflict_start_date

* This line stsets the data.  Conflicts are identified by dyadid, and term 
* refers to whether or not a conflict was terminated in this period. 
stset t, id(dyadid) failure(term==1)


*The output wil display the following:
/*

. stset t, id(dyadid) failure(term==1)

                id:  dyadid
     failure event:  term == 1
obs. time interval:  (t[_n-1], t]
 exit on or before:  failure

------------------------------------------------------------------------------
     2426  total obs.
        0  exclusions
------------------------------------------------------------------------------
     2426  obs. remaining, representing
      404  subjects
      356  failures in single failure-per-subject data
   784302  total analysis time at risk, at risk from t =         0
                             earliest observed entry t =         0
                                  last observed exit t =     20056

*/

* Stata calculates each observation's time interval from the end of the previous 
* observation until the end date provided by t.  The first observation is (corectly)
* assumed to begin at t = 0.  




* The analysis is then repeated with the new data
stcox tc scc mcap arcp fcap lpw terr coups ef ethnic lngdppc demdum act2 lnpop , nohr cluster(confid)
*stcurve, hazard



/* 

What are the differences with the new results?

All rebel strength variables remain positive, however, strong central command is
now statistically significant, whereas mobilization capacity and arm-procurement
capacity are no longer significant.  Thus, strong central command is the only 
rebel strength variable that is significant.

War on core territory becomes significant at the .10 level.

ELF is no longer significant.

GDP is no longer significant.

Population is no longer significant.

*/




