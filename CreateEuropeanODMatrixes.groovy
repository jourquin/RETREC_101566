package scripts;

import edu.uclouvain.core.nodus.NodusC;
import edu.uclouvain.core.nodus.NodusMapPanel;
import edu.uclouvain.core.nodus.NodusProject;
import edu.uclouvain.core.nodus.database.JDBCField;
import edu.uclouvain.core.nodus.database.JDBCUtils;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashMap;

public class CreateEuropeanODMatrixes_ {

  // Replace "xxx" with "iww", "rail" or "road"
  String inputOD = "od2010l2_xxx";
  String outputOD = "europel2_xxx";

  String centroidsTable = "centroidsl2";
  
  String[] europeanCountries = [
    "AD", "AT", "BE", "BG", "CH", "CZ", "DE", "AL", "AM", "AT", "BA", "BE", "BG", "CH", "CZ", "DE",\
    "DK", "ES", "FR", "GI", "GR", "HR", "HU", "IT", "LI", "LU", "ME", "NL", "PL", "PT", "RO", "RS",\
    "SI", "SK", "SM"\
  ];

  String[] regionsToIngnore = [
    "AM99", "DK01", "DK02", "DK04", "DK05", "GR41", "GR42", "GR43", "PT30", "ES70", "ES63", "ES53",\
    "ES64", "ITG2", "ITG1", "FR83"\
  ];
  
  HashMap<Integer, String> retainedCentroids = new HashMap<Integer, String>();

  // Check if a centroid is in the region of interest
  private String getEuropeanCountry(int centroidId, String nutsId) {
    nutsId = nutsId.toUpperCase();
    for (int i = 0; i < europeanCountries.length; i++) {
      if (nutsId.startsWith(europeanCountries[i])) {
        return europeanCountries[i];
      }
    }
    return null;
  }

  // Check if a centroid is in an excluded NUTS2 region
  private boolean isExcluded(String nutsId) {
    nutsId = nutsId.toUpperCase();
    for (int i = 0; i < regionsToIngnore.length; i++) {
      if (nutsId.startsWith(regionsToIngnore[i])) {
        return true;
      }
    }
    return false;
  }

  public CreateEuropeanODMatrixes_(NodusMapPanel nodusMapPanel) {

    NodusProject nodusProject = nodusMapPanel.getNodusProject();
    Connection jdbcConnection;

    // Get JDBC connection to the project database
    jdbcConnection = nodusProject.getMainJDBCConnection();

    // Read the centroids
    System.out.println("Loading centroids...");
    try {
      Statement stmt = jdbcConnection.createStatement();
      String sqlStmt = "SELECT num, nuts_id FROM " + centroidsTable;
      ResultSet rs = stmt.executeQuery(sqlStmt);
      while (rs.next()) {
        int centroidId = rs.getInt(1);
        String nutsId = rs.getString(2);
        String beneluxPlusRegion = getEuropeanCountry(centroidId, nutsId);
        if (beneluxPlusRegion != null && !isExcluded(nutsId)) {
          retainedCentroids.put(centroidId, beneluxPlusRegion);
        }
      }
      rs.close();
      stmt.close();
    } catch (SQLException e) { // TODO Auto-generated catch block
      e.printStackTrace();
      return;
    }

    // Create output table structure
    JDBCUtils jdbcUtils = new JDBCUtils(jdbcConnection);
    JDBCField[] field = new JDBCField[4];
    field[0] = new JDBCField(NodusC.DBF_GROUP, "NUMERIC(2,0)");
    field[1] = new JDBCField(NodusC.DBF_ORIGIN, "NUMERIC(10,0)");
    field[2] = new JDBCField(NodusC.DBF_DESTINATION, "NUMERIC(10,0)");
    field[3] = new JDBCField(NodusC.DBF_QUANTITY, "NUMERIC(10,0)");
    jdbcUtils.createTable(outputOD, field);

    // Filter the input table and save the result in the output table
    System.out.println("Filetring OD table...");
    try {
      Statement stmt = jdbcConnection.createStatement();
      String sqlStmt = "SELECT grp, org, dst, qty FROM " + inputOD;
      ResultSet rs = stmt.executeQuery(sqlStmt);

      PreparedStatement pStmt =
          jdbcConnection.prepareStatement("INSERT INTO " + outputOD + " VALUES(?,?,?,?)");

      while (rs.next()) {
        int grp = rs.getInt(1);
        int org = rs.getInt(2);
        int dst = rs.getInt(3);
        double qty = rs.getDouble(4);

        // Save in output table if both nodes are in region of interest
        String region1 = retainedCentroids.get(org);
        String region2 = retainedCentroids.get(dst);

        if (region1 != null && region2 != null) {
          pStmt.setInt(1, grp);
          pStmt.setInt(2, org);
          pStmt.setInt(3, dst);
          pStmt.setDouble(4, qty);
          pStmt.executeUpdate();
        }
      }
      rs.close();
      stmt.close();
      pStmt.close();
    } catch (SQLException e) {
      e.printStackTrace();
      return;
    }

    System.out.println("Done.");
  }
}

//Uncomment to use as script
new CreateEuropeanODMatrixes_(nodusMapPanel);