# coding: utf-8

import pandas as pd
import biogeme.database as db
import biogeme.biogeme as bio
import biogeme.models as models
from biogeme.expressions import Beta, exp, log, Derive, Variable
from BiogemeUtils import dropExistentOutput
import os
import mysql.connector
import time
from IPython.core.display_functions import display
    
def run(): 

    # Model 90 = log(cost) + log(duration_mode)
    # Model 91 = log(cost) + log(duration_mode) + accessibilities (exponential decay) 
    # Model 92 = log(cost) + log(duration_mode) + accessibilities (exponential normal decay - S shape)
    # Model 93 = log(cost) + log(duration_mode) + accessibilities (exponential square-root decay)
    # Model 94 = log(cost) + log(duration_mode) + accessibilities (log-normal decay)
    # Model 95 = log(cost) + log(duration_mode) + accessibilities (power decay)
    
    model = 92
    
    
    # Change output dir to "models". Create it if needed.
    wd = os.getcwd() + '/models'
    if not os.path.exists(wd):
        os.mkdir(wd)
    os.chdir(wd)
    
    # Solve for the groups present in the input table
    #for g in [0]: 
    for g in range(10): 
        
        #g = 0
        print("Solve model " + str(model) + " for group " + str(g))
        
        # Load input data
        con = mysql.connector.connect(user='nodus', password='nodus', host='127.0.0.1', database='retrec')
        curs = con.cursor()
        
        
        if g != 4:
            curs.execute("select * from biogeme_europel2 where grp = " + str(g), con)
        else:
            # Strange outlier in dataset for group 4 that must be removed
            curs.execute("select * from biogeme_europel2 where qty2 < 1200000 and grp = " + str(g), con)
            
        columns = [desc[0] for desc in curs.description]  # Get column headers
      
        # Convert the list of tuples to a df
        df = pd.DataFrame(curs.fetchall(), columns=columns) 
        curs.close()
        con.close()
        
        # Transform object to numeric values
        df = df.apply(pd.to_numeric, errors='coerce')
      
        # Convert column names to lower case 
        df.columns = map(str.lower, df.columns)
           
        # Replace NA values 
        df = df.fillna(df.max())
    
        # Express durations in hours
        df['duration1'] = df['duration1'] / 3600
        df['duration2'] = df['duration2'] / 3600
        df['duration3'] = df['duration3'] / 3600
        
        # Express quantities in Mios tons 
        df['qty1from'] = df['qty1from'] * 0.000001
        df['qty2from'] = df['qty2from'] * 0.000001
        df['qty3from'] = df['qty3from'] * 0.000001
        df['qty1to'] = df['qty1to'] * 0.000001
        df['qty2to'] = df['qty2to'] * 0.000001
        df['qty3to'] = df['qty3to'] * 0.000001  
        
        # Express lengths per 1000km 
        df['length1'] = df['length1'] * 0.001 
        df['length2'] = df['length2'] * 0.001 
        df['length3'] = df['length3'] * 0.001 
             
         
        # Replace NA values 
        df = df.fillna(df.max())
                
        # Convert column names to lower case 
        df.columns = map(str.lower, df.columns)
          
        # Use column names as Python variables 
        database = db.Database('data', df)
        globals().update(database.variables)
            
        # Weights must be relative to sample size in Biogeme
        total = df['qty'].sum()
        df['qty'] = database.get_sample_size() * df['qty'] / total
        
        # Parameters to estimate
        INTERCEPT1 = Beta('intercept.1', 0, None, None, 1)  # Reference mode -> intercept forced to be 0
        INTERCEPT2 = Beta('intercept.2', 0, None, None, 0)
        INTERCEPT3 = Beta('intercept.3', 0, None, None, 0)
        
        # Cost and duration estimators      
        B_COST = Beta('b_cost', 0, None, 0, 0)
        B_DURATION1 = Beta('b_duration.1', 0, None, 0, 0) 
        B_DURATION2 = Beta('b_duration.2', 0, None, 0, 0) 
        B_DURATION3 = Beta('b_duration.3', 0, None, 0, 0) 
          
        # Connectivity estimators per mode 
        B_ACC_FROM1 = Beta('b_acc_from.1', 0, 0, None, 0)
        B_ACC_FROM2 = Beta('b_acc_from.2', 0, 0, None, 0)
        B_ACC_FROM3 = Beta('b_acc_from.3', 0, 0, None, 0)
        B_ACC_TO1 = Beta('b_acc_to.1', 0, 0, None, 0)
        B_ACC_TO2 = Beta('b_acc_to.2', 0, 0, None, 0)
        B_ACC_TO3 = Beta('b_acc_to.3', 0, 0, None, 0)
        
        # Decay function parameter
        B_DECAY = Beta('b_decay', 0, None, 0, 0)
        
        B_DECAY_FROM = Beta('b_decay_from', 0, None, 0, 0)
        B_DECAY_TO = Beta('b_decay_to', 0, None, 0, 0)
         
        # Utility functions
        modelName = 'Model' + str(model)   
        
        if model == 90:
            V1 = INTERCEPT1 + B_COST * log(cost1)  + B_DURATION1 * log(duration1)
            V2 = INTERCEPT2 + B_COST * log(cost2)  + B_DURATION2 * log(duration2)
            V3 = INTERCEPT3 + B_COST * log(cost3)  + B_DURATION3 * log(duration3)
            
        if model == 91:
            V1 = INTERCEPT1 + B_COST * log(cost1)  + B_DURATION1 * log(duration1) + (B_ACC_FROM1 * qty1from + B_ACC_TO1 * qty1to) * exp(length1 * B_DECAY)
            V2 = INTERCEPT2 + B_COST * log(cost2)  + B_DURATION2 * log(duration2) + (B_ACC_FROM2 * qty2from + B_ACC_TO2 * qty2to) * exp(length2 * B_DECAY)
            V3 = INTERCEPT3 + B_COST * log(cost3)  + B_DURATION3 * log(duration3) + (B_ACC_FROM3 * qty3from + B_ACC_TO3 * qty3to) * exp(length3 * B_DECAY)
            
        if model == 92:
            V1 = INTERCEPT1 + B_COST * log(cost1)  + B_DURATION1 * log(duration1) + (B_ACC_FROM1 * qty1from + B_ACC_TO1 * qty1to) * exp(length1 ** 2 * B_DECAY)
            V2 = INTERCEPT2 + B_COST * log(cost2)  + B_DURATION2 * log(duration2) + (B_ACC_FROM2 * qty2from + B_ACC_TO2 * qty2to) * exp(length2 ** 2 * B_DECAY)
            V3 = INTERCEPT3 + B_COST * log(cost3)  + B_DURATION3 * log(duration3) + (B_ACC_FROM3 * qty3from + B_ACC_TO3 * qty3to) * exp(length3 ** 2 * B_DECAY)   
            
        if model == 93:
            V1 = INTERCEPT1 + B_COST * log(cost1)  + B_DURATION1 * log(duration1) + (B_ACC_FROM1 * qty1from + B_ACC_TO1 * qty1to) * exp(length1 ** 0.5 * B_DECAY)
            V2 = INTERCEPT2 + B_COST * log(cost2)  + B_DURATION2 * log(duration2) + (B_ACC_FROM2 * qty2from + B_ACC_TO2 * qty2to) * exp(length2 ** 0.5 * B_DECAY)
            V3 = INTERCEPT3 + B_COST * log(cost3)  + B_DURATION3 * log(duration3) + (B_ACC_FROM3 * qty3from + B_ACC_TO3 * qty3to) * exp(length3 ** 0.5 * B_DECAY)  
            
        if model == 94:
            V1 = INTERCEPT1 + B_COST * log(cost1)  + B_DURATION1 * log(duration1) + (B_ACC_FROM1 * qty1from + B_ACC_TO1 * qty1to) * exp(log(length1) ** 2 * B_DECAY)
            V2 = INTERCEPT2 + B_COST * log(cost2)  + B_DURATION2 * log(duration2) + (B_ACC_FROM2 * qty2from + B_ACC_TO2 * qty2to) * exp(log(length2) ** 2 * B_DECAY)
            V3 = INTERCEPT3 + B_COST * log(cost3)  + B_DURATION3 * log(duration3) + (B_ACC_FROM3 * qty3from + B_ACC_TO3 * qty3to) * exp(log(length3) ** 2 * B_DECAY)
            
        if model == 95:
            V1 = INTERCEPT1 + B_COST * log(cost1)  + B_DURATION1 * log(duration1) + (B_ACC_FROM1 * qty1from + B_ACC_TO1 * qty1to) * length1 ** B_DECAY
            V2 = INTERCEPT2 + B_COST * log(cost2)  + B_DURATION2 * log(duration2) + (B_ACC_FROM2 * qty2from + B_ACC_TO2 * qty2to) * length2 ** B_DECAY
            V3 = INTERCEPT3 + B_COST * log(cost3)  + B_DURATION3 * log(duration3) + (B_ACC_FROM3 * qty3from + B_ACC_TO3 * qty3to) * length3 ** B_DECAY
            
            
        # Model definition      
        V = {1: V1, 2: V2, 3: V3}
        av = {1: avail1, 2: avail2, 3: avail3}      
        logprob = models.loglogit(V, av, choice)
        formulas = {'loglike': logprob, 'weight': qty}
       
        biogeme = bio.BIOGEME(database, formulas)
        
        # Run the logit
        biogeme.modelName = modelName + '-' + str(g)
        dropExistentOutput(biogeme.modelName)
        
        # Print the estimated parameters
        start_time = time.time()
        results = biogeme.estimate()
        pandasResults = results.get_estimated_parameters()
        print(pandasResults)
         
        print("Model solved in %s seconds." % (time.time() - start_time))
        print()

    
    print("Done.")
    
if __name__ == "__main__":
    run()

