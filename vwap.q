Pi:3.14159265359;

// use maxInt/getUniform from rng of qcs - this exercise mainly use dictionary of qcs
.qcs.rng.maxInt:`long$(-1+2 xexp 31);
.qcs.rng.genUniform:{ rand(.qcs.rng.maxInt)%.qcs.rng.maxInt };

//box-muller - generate normal from uniform － generate two observation
.qcs.rng.genNorm:{
    z1:(sqrt -2*log x1:.qcs.rng.genUniform[])*sin 2*Pi*x2:.qcs.rng.genUniform[];
    z2:(sqrt -2*log x2)*cos 2*Pi*x1;
    (z1, z2)
    };

//stock simulation - create a schema to hold the data - for price of the stock
.qcs.sample.container: flip (`date`sym`timeStamp`price`volume)!("d"$();"s"$();"p"$();"f"$();"j"$());

//starting time of the trade
.qcs.mc.startTradingTime:09:00:00.000;

// generate 3000 ms random variable (0-3s) -> step means the number of variables, \scan - series of random number cumsum
.qcs.mc.generateTimeStamps:{[steps]
   .qcs.mc.startTradingTime+\steps#rand(3000)
    };

//determine dt - use ms as the unit for the trading
yearMiliseconds:365*24*60*60*1000;

// simulate stock function using Geometric Brownian Motion - input: spot price, drift, sig - volatility, time step n
.qcs.mc.simulateStock:{[spot;drift;sig;steps]
    timeStamp:.qcs.mc.generateTimeStamps[steps];

    // 1_ remove 1st dummy variable, 0-': rolling difference, calculate the incremental difference of given time stamp
    dts:1_0-':timeStamp;

    // GBM function, function mapping using projection - g:f[1;;] => g 2 3, anonymous function into projection
    f:{[mu;sig;dt;z] exp(mu-0.5*sig*sig)*dt+sig*z*sqrt(dt)}[drift;sig;;];

    //f:{[mu;sig;dt;z] exp(mu-0.5*sig*sig)*dt+sig*z*sqrt(dt)}
    //g:f[drift;sig;;]

    //.qcs.rng.genNorm each 100#(::) - generate pairs of obeservation
    //raze function used to reduced to one dimension
    //1st one is not random, so get rid of the 1st shock

    qnorms:(steps-1)#raze .qcs.rng.genNorm each steps#(::);

    // \scan function, apply f function with dt and z, here dt = dts%yearMiliseconds, and z = qnorms
    // use f to do a each both on dt and z-- entry to entry
    prices:spot *\ (dts%yearMiliseconds) f' qnorms;

    // combine spot and prices (to match the dimension as prices is n-1) and cast to float
    // rand each steps#10000: rand(10000), rand(10000), rand(10000)....

    t:flip `timeStamp`price`volume!(timeStamp;"f"$spot, prices;rand each steps#10000);

    // select the time for the trading
    select from t where timeStamp<16:00:00.000
    };


.qcs.mc.simulateStockByDate:{[d1;stock;drift;sig;steps]

    // spot price is based on market close price
    spot:last exec price from .qcs.sample.container where sym=stock;

    // set up the 1st day
    if[spot=0n;spot:rand(100)+20];

    // simulate stock using qcs.mc functionality
    res:.qcs.mc.simulateStock[spot;drift;sig;steps];

    // with update on timestamp -adding the date
    res:`date`sym`timeStamp xcols update timeStamp:d1+timeStamp, date:d1, sym:stock from res;

    // append to the container
    `.qcs.sample.container upsert res;

    };

// set up the number of trade per day per stocl
num_trade:1000;

// assuming there are 15 stocks
.qcs.sample.createSampleStock:{[days]

    // clear the previous simulation data
    delete from `.qcs.sample.container;

    // create symbol of the data
    sym:`stock1`stock2`stock3`stock4`stock5`stock6`stock7`stock8`stock9`stock10`stock11`stock12`stock13`stock14`stock15`stock16`stock17`stock18`stock19`stock20`stock20`stock21`stock22`stock23`stock24`stock25;

    // construct 30 trading days with weekends removed

    // create the last 60 days date time array
    dates:.z.D-til 2*days;

    // flip (enlist `date)!enlist dates - generate a date table
    // remove the saturdays and sundays by mod6 = 0/1
    // reverse to get the ascending day order
    dates:reverse days#exec date from (flip (enlist `date)!enlist dates) where not (date mod 6) within (0;1);

    // generate volatility for each stock
    // construct the dictionary
    .qcs.sample.sigs:sym!.qcs.rng.genUniform each (count sym)#(::);

    // generate 500 obeservation per day
    // pass a length two list called [dd], dd[0]- date, dd[1] - stock;
    f:{[dd] .qcs.mc.simulateStockByDate[dd[0];dd[1];0.05;.qcs.sample.sigs[dd[1]];num_trade]};

    // /:\: cartesian product of two list (dates and sym)
    // put the result to list - use raze to reduce to one dimension
    f each raze dates ,/:\: sym;

    //sorting timestamp in ascending order to container data
    `timeStamp xasc `.qcs.sample.container;

    };

//produce vwap prices for each date
.qcs.sample.getVwap:{
    select vwap:(sum price*volume)%(sum volume) by date, sym  from .qcs.sample.container
    //this is the one to calculate the vwap
    };

// file to test the output
//.qcs.sample.createSampleStock[30]; //
//.qcs.sample.getVwap[] //
//vwap_table:.qcs.sample.getVwap[];

//.Q.w[] //check memory in Q

// saving to the output
//`:stockTimeSeries.csv 0:.h.tx[`csv; .qcs.sample.container];
//`:stockVWAP.csv 0:.h.tx[`csv; vwap_table];