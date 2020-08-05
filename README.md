# India Housing
This is the repository for analysis of housing finance in TN and India.

1. Data source: 

NSS:

+ NSS76: http://mospi.gov.in/unit-level-data-report-nss-76th-round-schedule-12-july-december-2018-drinking-water-sanitation
+ NSS49, 58, 63, 65. 69: http://microdata.gov.in/nada43/index.php/catalog#_r=1592330533169&collection=&country=&dtype=&from=1975&page=1&ps=&sid=&sk=housing&sort_by=rank&sort_order=desc&to=2017&topic=&view=s&vk=

IHDS:

+ 2011-12: https://www.icpsr.umich.edu/web/DSDR/studies/36151
+ 2005: https://www.icpsr.umich.edu/web/DSDR/studies/22626

2. Do files: 
+ "survey"+"survey number".do is the file to generate indicators for each survey . 
+ batch_"survey".do consolidate the surveys. 

3. Microdata:
+ master.dta : consolidated household survey from round 76 (2018), round 69 (2012), round 65 (2018), round 49 (1993), round 58 (2002)

4. Note: 
The state might be coded differently for survey 49 and 58. Please refer to the appendix for state code in each survey report.  
http://microdata.gov.in/nada43/index.php/catalog#_r=1592330533169&collection=&country=&dtype=&from=1975&page=1&ps=&sid=&sk=housing&sort_by=rank&sort_order=desc&to=2017&topic=&view=s&vk=
