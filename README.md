This repository contains all the data and scripts used in the framework
of the paper « ***Direct and cross cost elasticity estimations for
freight transport in Europe using constructed dependent variables*** »
published in Research in Transportation Economics in June 2025
(<https://doi.org/10.1016/j.retrec.2025.101566>).

Needed (open source) software packages:

- Nodus : <http://nodus.uclouvain.be> (download and install the binary
  package provided on GitHub
  (<https://github.com/jourquin/Nodus/releases>).

- MySQL / MariaDB: <https://mariadb.com>

- Python and the Biogeme package: <https://biogeme.epfl.ch>

- Download the content of this GitHub repository (from the "releases"
  section).

These are the steps needed to compute the elasticities:

1.  Create a "retrec" database in MariaDB. Create a user named "nodus"
    with the password "nodus" and grant all privileges to "nodus" for
    the "retrec" database.

2.  Launch Nodus and open the "retrec.nodus" project. This will import
    and display the digitized networks.

3.  Unzip the "ETIS.zip" file. In the Nodus SQL console, open the 
    "CreateODs.sql" script. Run it for each mode separately by
    replacing "xxx" with "road", "iww" or "rail". This will import
    the ETIS modeled OD matrices for 2020, provided as CSV files.

4.  In the Nodus GROOVY console, load and run the
    "CreateEuropeanODMatrixes.groovy" script, once for each
    transportation mode. This will create a subset of the complete
    matrices. The output matrices are used in the framework of the
    paper.

5.  In the Nodus SQL console, load and run the "MergeODs.sql" script.
    This will create a matrix that contains the demand for the three
    transportation modes. The modal split method will be applied to this
    merged matrix.

6.  In Nodus, perform a first, uncalibrated, assignment (scenario 0).

7.  In the Nodus SQL console, load and run the "CreateMNLogitInput.sql"
    script. This will create the 'uncalibrated_europel2" table,
    containing the needed data for the logit model.

8.  In the Nodus SQL console, load and run the "CreateBiogemeInput.sql"
    script, which transforms the previous table into the format needed
    by Biogeme ("biogeme_europel2" table).

9.  Run the Biogeme "SolveIntegratedModel.py" Python script. Note that
    the exponential normal decay function (model 92) is used in the
    paper. The outputs are stored in the "models" subdirectory.

10. Report the estimated parameters in the "calibrated.costs" file. Note
    that this is already done in the provided "calibrated.costs" file.

11. Perform a second, calibrated, assignment (scenario 1). This
    assignment uses the user defined modal choice plugin, which Java
    source code can be found in the "ModalSplitPlugin" directory.

12. Run three additional assignments, modifying the costs for each mode:

    a.  Scenario 2: set "reRoadCost" to 1.05 in "calibrated.costs"

    b.  Scenario 3: set "reIWWCost" to 1.05 in "calibrated.costs"

    c.  Scenario 4: set "reRailCost" to 1.05 in "calibrated.costs"

13. In the Nodus SQL console, run the "t.sql" script to retrieve the
    transported tons for each mode in the scenarios 1, 2, 3 and 4.
    Report the output in the "Elasticities.xlsx" Excel file (in the
    "Elasticities" subdirectory). This is already done in the provided
    Excel sheet.
