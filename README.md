# BDIF_B
Big data assignment B - VWAP implementation in q by Yue Wang

There are three parameteres associated with the program...
1st parameter: one is num_trade, which stands for how many trade per security on a daily basis- now set for 20000
Note 1: (if need change, change num_trade within vwap.q)


2nd parameter: the other is num of security, - the program assume to be 15 security, with labels - stock1 through stock15 - will accomodate to 30 security 
Note 2: (if need change, change the symbol line by appending more symbols


3rd parameter: is the num of days

To test the file:


1. download the file to local repository


2. open q and load file by \l vwap.q3. .qcs.sample.createSampleStock[30]; (this will create the simulated stock, save it to .qcs.sample.container)


4. vwap_table:.qcs.sample.getVwap[]; (get vwap price and save to table defined)


5. `:stockTimeSeries.csv 0:.h.tx[`csv; .qcs.sample.container;  (save to the stockTimeSeries.csv)


6. `:stockVWAP.csv 0:.h.tx[`csv; res];(save to the stockVWAP.csv)
