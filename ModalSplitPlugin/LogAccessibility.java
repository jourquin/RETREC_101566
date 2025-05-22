/*
 * Copyright (c) 1991-2023 Université catholique de Louvain
 *
 * <p>Center for Operations Research and Econometrics (CORE)
 *
 * <p>http://www.uclouvain.be
 *
 * <p>This file is part of Nodus.
 *
 * <p>Nodus is free software: you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * <p>This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * <p>You should have received a copy of the GNU General Public License along with this program. If
 * not, see http://www.gnu.org/licenses/.
 */

import edu.uclouvain.core.nodus.NodusC;
import edu.uclouvain.core.nodus.NodusProject;
import edu.uclouvain.core.nodus.compute.assign.AssignmentParameters;
import edu.uclouvain.core.nodus.compute.assign.modalsplit.ModalSplitMethod;
import edu.uclouvain.core.nodus.compute.assign.modalsplit.Path;
import edu.uclouvain.core.nodus.compute.assign.modalsplit.PathsForMode;
import edu.uclouvain.core.nodus.compute.assign.workers.PathWeights;
import edu.uclouvain.core.nodus.compute.od.ODCell;
import edu.uclouvain.core.nodus.database.JDBCUtils;
import edu.uclouvain.core.nodus.tools.console.NodusConsole;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Properties;

/**
 * This modal split method uses parameters that are estimated using the Biogeme Python package. The
 * parameters must be estimated using data that corresponds to the cheapest computed route for each
 * mode, whatever the means used.
 *
 * <p>This method is based on an utility function on cost, transit time and connectivity.
 *
 * <p>See the SolveIntegratedModel.py script for the estimation of the parameters.
 *
 * <p>Once the modal split computed, the quantity assigned to each mode is spread over the available
 * means proportionally to their relative costs.
 *
 * @author Bart Jourquin
 */
public class LogAccessibility extends ModalSplitMethod {

  static final String EXPONENTIAL = "exponential";
  static final String EXPONENTIAL_NORMAL = "exponential_normal";

  // Name of the table that contains the total quantities transported from and to each centroid
  String totalQtyTable;

  // Mode specific estimators
  double[] intercept;
  double[] b_acc_from;
  double[] b_acc_to;
  double[] b_duration;
  double[] mu;
  
  // Generic estimators
  double b_cost;
  double b_decay;

  // Cost functions containing the estimators
  Properties costFunctions;

  // Hashmap that contains the total quantity transported from and to each centroid.
  private class TotalQty {
    double qtyFrom;
    double qtyTo;

    TotalQty(double qtyFrom, double qtyTo) {
      this.qtyFrom = qtyFrom;
      this.qtyTo = qtyTo;
    }

    public double getQtyFrom() {
      return qtyFrom;
    }

    public double getQtyTo() {
      return qtyTo;
    }
  };

  HashMap<String, TotalQty> totalQty_HashMap;

  // Test if tables exists
  boolean totalQtyTableExists = true;

  String decayFunction;

  NodusProject nodusProject;

  /**
   * Default constructor. Calls the super class.
   *
   * @param nodusProject Nodus project to associate to this method.
   */
  public LogAccessibility(NodusProject nodusProject) {
    super(nodusProject);
  }

  /**
   * Initializes the method with the right parameters at the assignment level . This is called by
   * the assign() method of the multiflow assignment.
   *
   * @param assignmentParameters Assignment parameters
   */
  public void initialize(AssignmentParameters assignmentParameters) {
    super.initialize(assignmentParameters);

    nodusProject = getNodusProject();
    costFunctions = getAssignmentParameters().getCostFunctions();

    // Get the functional form of the decay function (exponential by default)
    decayFunction = costFunctions.getProperty("@DecayFunction", EXPONENTIAL_NORMAL).toLowerCase();
    if (!decayFunction.equals(EXPONENTIAL)) {
      decayFunction = EXPONENTIAL_NORMAL;
    }
   
    // Get total quantities table name
    totalQtyTable = costFunctions.getProperty("@TotalQtyTable", "totalQty");

    if (!JDBCUtils.tableExists(totalQtyTable)) {
      System.err.println("Table " + totalQtyTable + " not found in database.");
      totalQtyTableExists = false;
    }
  }

  /**
   * Initializes the method at the worker thread level.
   *
   * @param currentGroup Group ID for the commodities
   */
  public void initializeGroup(int currentGroup) {
    super.initializeGroup(currentGroup);

    if (!totalQtyTableExists) {
      return;
    }

    // Get the generic estimators
    b_cost = getValue("b_cost");
    b_decay = getValue("b_decay");
    
    // Mode specific estimators
    intercept = new double[NodusC.MAXMM];
    b_duration = new double[NodusC.MAXMM];
    b_acc_from = new double[NodusC.MAXMM];
    b_acc_to = new double[NodusC.MAXMM];
    mu = new double[NodusC.MAXMM];
    
    for (int m = 0; m < NodusC.MAXMM; m++) {
      intercept[m] = getValue("intercept." + m);
      b_duration[m] = getValue("b_duration." + m);
      b_acc_from[m] = getValue("b_acc_from." + m);
      b_acc_to[m] = getValue("b_acc_to." + m);
      
      // For the  Heteroscedastic Extreme Value (HEV) specification
      mu[m] = getValue("mu." + m);
      if (mu[m] == 0) { // if not defined, set to 1
    	  mu[m] = 1.0;
      }
    }

    // Load total quantities transported from and to each centroid
    try {
      Connection con = nodusProject.getMainJDBCConnection();
      Statement stmt = con.createStatement();

      totalQty_HashMap = new HashMap<String, TotalQty>();
      String sqlStmt =
          "select num, ldmode, qtyfrom, qtyto from "
              + totalQtyTable
              + " where grp = "
              + getCurrentGroup();
      ResultSet rs = stmt.executeQuery(sqlStmt);

      // Retrieve result of query
      while (rs.next()) {
        int num = rs.getInt(1);
        int mode = rs.getInt(2);
        double qtyFrom = rs.getDouble(3);
        double qtyTo = rs.getDouble(4);

        String key = num + "-" + mode;

        totalQty_HashMap.put(key, new TotalQty(qtyFrom, qtyTo));
      }

      rs.close();
      stmt.close();
    } catch (Exception ex) {
      new NodusConsole();
      System.err.println(ex.toString());
      return;
    }
  }

  @Override
  public String getPrettyName() {
    return "Ln(C) + Ln(T) + Accessibility";
  }

  @Override
  public String getName() {
    // Cost Transit Time AccessibilityFrm AccessibilityTo
    return "lnC-lnTT-Access";
  }

  /**
   * Compute the utility for the cheapest path of a mode.
   *
   * @param modalPaths List of alternative paths
   * @param trade Total transported quantity on this OD relation
   * @return PathsForMode The updated list
   */
  private PathsForMode computeUtility(ODCell odCell, PathsForMode modalPaths, double trade) {
    PathWeights c = modalPaths.cheapestPathWeights;
    int mode = modalPaths.loadingMode;

    // Get the total cost of the OD relation
    double totalCost = c.getCost();

    // Get the transit time (in hours)
    double transitTime = c.getTransitTime() / 3600;

    // Get the trip length (per 100 km)
    double length = c.getLength() * 0.001;

    // Get the  total quantity at origin and destination centroids (1000 tons)
    String key = odCell.getOriginNodeId() + "-" + mode;
    TotalQty totalQty = totalQty_HashMap.get(key);
    if (totalQty == null) {
      System.err.println("key " + key + " not found!");
      return null;
    }

    double qtyFrom = totalQty.getQtyFrom() * 0.000001;
    double qtyTo = totalQty.getQtyTo() * 0.000001;

    // Compute utility function
    if (decayFunction.equals(EXPONENTIAL_NORMAL)) {
      modalPaths.utility = mu[mode] *
          (intercept[mode]
              + b_cost * Math.log(totalCost)
              + b_duration[mode] * Math.log(transitTime)
              + (b_acc_from[mode] * qtyFrom + b_acc_to[mode] * qtyTo)
                  * Math.exp(Math.pow(length, 2) * b_decay));
    } else {
      modalPaths.utility = mu[mode] *
          (intercept[mode]
              + b_cost * Math.log(totalCost)
              + b_duration[mode] * Math.log(transitTime)
              + (b_acc_from[mode] * qtyFrom + b_acc_to[mode] * qtyTo)
                  * Math.exp(length * b_decay));
    }

    return modalPaths;
  }

  /**
   * Runs the modal split method algorithm.
   *
   * @param odCell The OD cell for which the modal split has to be performed.
   * @param pathsLists A list that contains the lists of routes for each mode.
   * @return True on success.
   */
  public boolean split(ODCell odCell, List<PathsForMode> pathsLists) {

    // If not correctly initialized...
    if (!totalQtyTableExists) {
      return false;
    }

    /*
     * Compute the market marketShare for each mode, based on the estimated utilities
     */
    double denominator = 0.0;
    Iterator<PathsForMode> plIt = pathsLists.iterator();
    while (plIt.hasNext()) {
      PathsForMode modalPaths = plIt.next();
      modalPaths = computeUtility(odCell, modalPaths, odCell.getQuantity());
      denominator += Math.exp(modalPaths.utility);
    }

    // Compute the market marketShare per mode
    plIt = pathsLists.iterator();
    while (plIt.hasNext()) {
      PathsForMode modalPaths = plIt.next();
      modalPaths.marketShare = Math.exp(modalPaths.utility) / denominator;
    }

    // Compute the market marketShare per path for each mode (proportional)
    plIt = pathsLists.iterator();
    while (plIt.hasNext()) {
      PathsForMode modalPaths = plIt.next();

      // Denominator for this mode
      denominator = 0.0;
      Iterator<Path> it = modalPaths.pathList.iterator();
      while (it.hasNext()) {
        Path path = it.next();
        denominator += Math.pow(path.weights.getCost(), -1);
      }

      // Spread over each path of this mode
      it = modalPaths.pathList.iterator();
      while (it.hasNext()) {
        Path path = it.next();
        path.marketShare =
            (Math.pow(path.weights.getCost(), -1) / denominator) * modalPaths.marketShare;
      }
    }
    return true;
  }

  /**
   * Returns the value of a given parameter for the current group.
   *
   * @param key The name of the estimator to fetch
   * @return The value of the parameter or 0 if not found
   */
  private double getValue(String key) {

    double ret = 0.0;
    String propName = key + "." + getCurrentGroup();

    String doubleString = costFunctions.getProperty(propName);

    if (doubleString != null) {

      try {
        ret = Double.parseDouble(doubleString.trim());
      } catch (NumberFormatException e) {
        ret = 0.0;
      }
    }

    return ret;
  }
}
